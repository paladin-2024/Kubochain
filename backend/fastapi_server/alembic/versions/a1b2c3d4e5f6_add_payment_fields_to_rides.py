"""add_payment_fields_to_rides

Revision ID: a1b2c3d4e5f6
Revises: 71c1a008b5b0
Create Date: 2026-05-25 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = '71c1a008b5b0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('rides', sa.Column('payment_method', sa.String(20), nullable=False, server_default='cash'))
    op.add_column('rides', sa.Column('payment_status', sa.String(20), nullable=False, server_default='pending'))
    op.add_column('rides', sa.Column('payment_phone', sa.Text(), nullable=True))
    op.add_column('rides', sa.Column('payment_reference', sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column('rides', 'payment_reference')
    op.drop_column('rides', 'payment_phone')
    op.drop_column('rides', 'payment_status')
    op.drop_column('rides', 'payment_method')
