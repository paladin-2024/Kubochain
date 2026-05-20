import logging
from enum import StrEnum

_audit = logging.getLogger("kubochain.audit")
if not _audit.handlers:
    _handler = logging.StreamHandler()
    _handler.setFormatter(
        logging.Formatter("%(asctime)s [AUDIT] %(levelname)s %(message)s", datefmt="%Y-%m-%dT%H:%M:%SZ")
    )
    _audit.addHandler(_handler)
    _audit.setLevel(logging.INFO)
    _audit.propagate = False


class AuditEvent(StrEnum):
    LOGIN_OK        = "login_ok"
    LOGIN_FAIL      = "login_fail"
    REGISTER_OK     = "register_ok"
    TOKEN_REFRESH   = "token_refresh"
    ACCOUNT_DISABLED = "account_disabled"
    WS_AUTH_FAIL    = "ws_auth_fail"
    WS_AUTH_OK      = "ws_auth_ok"


def audit(event: AuditEvent, *, ip: str = "-", user_id: str = "-", detail: str = ""):
    _audit.info("%s ip=%s user=%s %s", event.value, ip, user_id, detail)
