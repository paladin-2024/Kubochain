import asyncio, uuid, bcrypt
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

DATABASE_URL = "postgresql+asyncpg://kubochain:password@localhost:5433/kubochain"

def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()

async def seed():
    engine = create_async_engine(DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    admin_id = uuid.uuid4()
    phone    = "+243999000000"
    password = "Admin1234!"

    async with async_session() as session:
        async with session.begin():
            await session.execute(text("""
                INSERT INTO users (id, first_name, last_name, email, phone, password, role,
                                   rating, total_rides, is_active, created_at, updated_at)
                VALUES (:aid, 'Admin', 'KuboChain', 'admin@kubochain.com', :phone, :pwd,
                        'admin', 5.00, 0, true, now(), now())
                ON CONFLICT (email) DO UPDATE SET role = 'admin', is_active = true,
                    phone = :phone, password = :pwd
            """), {
                "aid": admin_id,
                "phone": phone,
                "pwd": hash_password(password),
            })

    await engine.dispose()
    print("\n✓ Admin user ready\n")
    print(f"  Phone     →  {phone}")
    print(f"  Password  →  {password}")
    print(f"\n  Dashboard login: enter  999000000  in the phone field\n")

asyncio.run(seed())
