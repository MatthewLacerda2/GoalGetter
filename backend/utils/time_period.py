from datetime import datetime, timedelta, timezone
from typing import Tuple

def get_yesterday_date_range() -> Tuple[datetime, datetime]:
    """
    Get yesterday's date range in UTC timezone.
    
    Returns:
        Tuple[datetime, datetime]: (yesterday_start, yesterday_end)
        - yesterday_start: Yesterday at 00:00:00 UTC
        - yesterday_end: Yesterday at 23:59:59.999999 UTC
    """
    now = datetime.now(timezone.utc)
    yesterday = now - timedelta(days=1)
    yesterday_start = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
    yesterday_end = yesterday.replace(hour=23, minute=59, second=59, microsecond=999999)
    return yesterday_start, yesterday_end
