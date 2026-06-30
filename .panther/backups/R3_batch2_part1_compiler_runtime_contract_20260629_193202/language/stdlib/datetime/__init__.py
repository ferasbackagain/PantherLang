from datetime import datetime, timezone

def now():
    return datetime.now(timezone.utc).isoformat()

def today():
    return datetime.now(timezone.utc).date().isoformat()
