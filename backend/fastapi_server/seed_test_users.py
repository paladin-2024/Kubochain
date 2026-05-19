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

    passenger_id = uuid.uuid4()
    rider_id     = uuid.uuid4()

    async with async_session() as session:
        async with session.begin():
            await session.execute(text("""
                INSERT INTO users (id, first_name, last_name, email, phone, password, role,
                                   rating, total_rides, is_active, created_at, updated_at)
                VALUES
                  (:pid, 'Test', 'Passenger', 'passenger@test.com', '+243812000001', :ppwd,
                   'passenger', 5.00, 0, true, now(), now()),
                  (:rid, 'Test', 'Driver', 'driver@test.com', '+243812000002', :rpwd,
                   'rider', 5.00, 0, true, now(), now())
                ON CONFLICT (email) DO NOTHING
            """), {
                "pid": passenger_id, "ppwd": hash_password("Test1234!"),
                "rid": rider_id,     "rpwd": hash_password("Test1234!"),
            })

            await session.execute(text("""
                INSERT INTO drivers (id, user_id, vehicle_make, vehicle_model, vehicle_color,
                                     vehicle_plate, vehicle_type, is_verified, is_online,
                                     rating, rating_count, total_rides, total_earnings,
                                     today_earnings, last_earnings_reset, created_at)
                VALUES (:did, :uid, 'Honda', 'CB500', 'Black', 'GOM-TEST-01', 'motorcycle',
                        true, false, 5.00, 0, 0, 0.00, 0.00, current_date, now())
                ON CONFLICT DO NOTHING
            """), {"did": uuid.uuid4(), "uid": rider_id})

    await engine.dispose()
    print("\n✓ Test users created\n")
    print("  Passenger  →  email: passenger@test.com  |  password: Test1234!")
    print("  Driver     →  email: driver@test.com     |  password: Test1234!\n")

asyncio.run(seed())
