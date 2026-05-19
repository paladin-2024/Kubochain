from ..config import get_settings

settings = get_settings()

_firebase_app = None


def _get_firebase():
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    try:
        import firebase_admin
        from firebase_admin import credentials
        cred = credentials.Certificate(settings.firebase_credentials_path)
        _firebase_app = firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"[FCM] Firebase init failed: {e}")
        _firebase_app = False
    return _firebase_app


async def send_push(
    *,
    token: str | None = None,
    tokens: list[str] | None = None,
    title: str,
    body: str,
    data: dict | None = None,
):
    app = _get_firebase()
    if not app:
        return

    try:
        from firebase_admin import messaging

        str_data = {k: str(v) for k, v in (data or {}).items()}
        notification = messaging.Notification(title=title, body=body)

        if token:
            msg = messaging.Message(notification=notification, data=str_data, token=token)
            messaging.send(msg)
        elif tokens:
            msg = messaging.MulticastMessage(notification=notification, data=str_data, tokens=tokens)
            messaging.send_each_for_multicast(msg)
    except Exception as e:
        print(f"[FCM] send error: {e}")
