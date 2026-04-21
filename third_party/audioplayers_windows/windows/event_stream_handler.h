#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>

#include <windows.h>

#include <deque>
#include <mutex>
#include <string>

using namespace flutter;

template <typename T = EncodableValue>
class EventStreamHandler : public StreamHandler<T>
{
public:
  EventStreamHandler() : dispatch_window_(CreateDispatchWindow()) {}

  ~EventStreamHandler() override
  {
    if (dispatch_window_ != nullptr)
    {
      ::DestroyWindow(dispatch_window_);
    }
  }

  void Success(std::unique_ptr<T> data)
  {
    if (!data)
    {
      return;
    }

    PendingPlatformEvent event(this, *data);
    DispatchOrQueueEvent(std::move(event));
  }

  void Error(const std::string &error_code,
             const std::string &error_message,
             const T &error_details)
  {
    PendingPlatformEvent event(this, error_code, error_message, error_details);
    DispatchOrQueueEvent(std::move(event));
  }

protected:
  std::unique_ptr<StreamHandlerError<T>> OnListenInternal(
      const T *arguments,
      std::unique_ptr<EventSink<T>> &&events) override
  {
    std::deque<PendingPlatformEvent> pending_events;
    {
      std::unique_lock<std::mutex> lock(m_mtx);
      m_sink = std::move(events);
      pending_events.swap(pending_events_);
    }

    for (const auto &event : pending_events)
    {
      HandleDispatchedEvent(event);
    }
    return nullptr;
  }

  std::unique_ptr<StreamHandlerError<T>> OnCancelInternal(
      const T *arguments) override
  {
    std::unique_lock<std::mutex> lock(m_mtx);
    m_sink.reset();
    pending_events_.clear();
    return nullptr;
  }

private:
  struct PendingPlatformEvent
  {
    PendingPlatformEvent(EventStreamHandler<T> *target, const T &payload)
        : handler(target), is_error(false), value(payload) {}

    PendingPlatformEvent(EventStreamHandler<T> *target,
                         const std::string &code,
                         const std::string &message,
                         const T &details)
        : handler(target),
          is_error(true),
          value(details),
          error_code(code),
          error_message(message) {}

    EventStreamHandler<T> *handler;
    bool is_error;
    T value;
    std::string error_code;
    std::string error_message;
  };

  static UINT DispatchWindowMessageId()
  {
    static const UINT kMessageId = ::RegisterWindowMessage(
        L"AudioplayersWindowsPlugin.EventStreamHandler.Dispatch");
    return kMessageId;
  }

  static LRESULT CALLBACK DispatchWindowProc(HWND hwnd,
                                             UINT message,
                                             WPARAM wparam,
                                             LPARAM lparam)
  {
    if (message == DispatchWindowMessageId())
    {
      auto *event = reinterpret_cast<PendingPlatformEvent *>(lparam);
      if (event != nullptr && event->handler != nullptr)
      {
        event->handler->HandleDispatchedEvent(*event);
      }
      return 0;
    }

    return ::DefWindowProc(hwnd, message, wparam, lparam);
  }

  static const wchar_t *DispatchWindowClassName()
  {
    return L"AudioplayersWindowsPlugin.EventStreamHandler.DispatchWindow";
  }

  static bool RegisterDispatchWindowClass()
  {
    static const bool kRegistered = []()
    {
      WNDCLASS window_class = {};
      window_class.lpfnWndProc = DispatchWindowProc;
      window_class.hInstance = ::GetModuleHandle(nullptr);
      window_class.lpszClassName = DispatchWindowClassName();

      return ::RegisterClass(&window_class) != 0 ||
             ::GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
    }();

    return kRegistered;
  }

  static HWND CreateDispatchWindow()
  {
    if (!RegisterDispatchWindowClass())
    {
      return nullptr;
    }

    return ::CreateWindowEx(0, DispatchWindowClassName(), L"", 0, 0, 0, 0,
                            0, HWND_MESSAGE, nullptr,
                            ::GetModuleHandle(nullptr), nullptr);
  }

  void DispatchEvent(PendingPlatformEvent &event)
  {
    if (dispatch_window_ == nullptr ||
        ::GetWindowThreadProcessId(dispatch_window_, nullptr) ==
            ::GetCurrentThreadId())
    {
      HandleDispatchedEvent(event);
      return;
    }

    ::SendMessage(dispatch_window_, DispatchWindowMessageId(), 0,
                  reinterpret_cast<LPARAM>(&event));
  }

  void DispatchOrQueueEvent(PendingPlatformEvent event)
  {
    {
      std::unique_lock<std::mutex> lock(m_mtx);
      if (!m_sink)
      {
        pending_events_.push_back(std::move(event));
        return;
      }
    }

    DispatchEvent(event);
  }

  void HandleDispatchedEvent(const PendingPlatformEvent &event)
  {
    std::unique_lock<std::mutex> lock(m_mtx);
    if (!m_sink)
    {
      return;
    }

    if (event.is_error)
    {
      m_sink->Error(event.error_code, event.error_message, event.value);
      return;
    }

    m_sink->Success(event.value);
  }

  HWND dispatch_window_ = nullptr;
  std::mutex m_mtx;
  std::unique_ptr<EventSink<T>> m_sink;
  std::deque<PendingPlatformEvent> pending_events_;
};