import time
import sys
import signal
import atexit

def spinner(stop_event=None, duration=5, message="Thinking..."):
    """Simple throbber: Spins until duration ends or stop_event is set."""
    #chars = "|/-\\"  # Common spinner chars
    chars = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"  # Common spinner chars
    start_time = time.time()
    i = 0
    
    def cleanup():
        sys.stdout.write("\r" + " " * len(message + " ") + "\r")
        sys.stdout.flush()
    
    atexit.register(cleanup)  # Clean up on exit
    
    while time.time() - start_time < duration and (stop_event is None or not stop_event.is_set()):
        sys.stdout.write(f"\r{message} {chars[i % len(chars)]}")
        sys.stdout.flush()
        i += 1
        time.sleep(0.1)
    
    print(f"\r{message} Done!")  # Replace with your completion message
    sys.stdout.flush()

# Usage in your app
if __name__ == "__main__":
    spinner(duration=3)  # Spins for 3 seconds
