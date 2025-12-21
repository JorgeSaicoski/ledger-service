# Architecture

## Overview

Ledger Service is a simple transaction recording microservice. It stores financial movements and calculates balances. Nothing more.

## Design Principles

1. **Single Responsibility**: Only records transactions and calculates sums
2. **Dumb Storage**: No business logic, no validation beyond data format
3. **Immutability**: Transactions are never deleted or modified
4. **Caller Trust**: Assumes calling services handle business rules

## System Context

```
┌─────────────────┐
│   API Gateway   │ ◄── External requests (authenticated)
└────────┬────────┘
│
┌────┴─────────────────────────┐
│   Internal Network           │
│                              │
│  ┌──────────────┐            │
│  │   Cashier    │            │
│  │   Service    │            │
│  └──────┬───────┘            │
│         │                    │
│  ┌──────▼───────┐            │
│  │   Loyalty    │            │
│  │   Service    │────┐       │
│  └──────────────┘    │       │
│                      │       │
│  ┌──────────────┐    │       │
│  │   Budget     │    │       │
│  │   Service    │────┤       │
│  └──────────────┘    │       │
│                      │       │
│               ┌──────▼──────────┐
│               │ Ledger Service  │
│               └──────┬──────────┘
│                      │
│               ┌──────▼──────────┐
│               │   PostgreSQL    │
│               └─────────────────┘
└──────────────────────────────────┘
```

## Security Model

### External Layer (API Gateway)
- Authentication (via Authentik or similar)
- Rate limiting
- DDoS protection
- Public internet boundary

### Internal Layer (Ledger Service)
- Input format validation only
- Trusts authenticated requests from gateway
- Not exposed publicly
- Validates data structure, not business rules

### What Ledger Service Validates
- `user_id`: Must be a valid lowercase UUID format (e.g., "550e8400-e29b-41d4-a716-446655440000") and Matches Authentik format (UUID/string pattern)
- Uppercase UUIDs are **not accepted**
- `amount`: Valid integer, no decimals allowed
- `currency`: Lowercase letters, numbers, and underscores only; max length 32
- SQL injection prevention (parameterized queries)

### What Ledger Service Does NOT Validate
- User existence in Authentik
- User permissions
- Balance sufficiency
- Business rules (reward multipliers, budget limits, etc.)

## Data Flow

### Creating a Transaction
```
1. Calling service → POST /transactions
2. Ledger validates input format
3. Ledger writes to PostgreSQL
4. Ledger returns transaction_id
```

### Getting Balance
```
1. Calling service → GET /balance?user_id=X&currency=Y
2. Ledger queries: SELECT SUM(amount) WHERE user_id=X AND currency=Y
3. Ledger returns calculated balance
```

### Transfer Example (Two Users)
```
Cashier Service orchestrates:
1. POST /transactions {user_id: "sender", amount: -1000, currency: "usd"}
2. POST /transactions {user_id: "receiver", amount: 1000, currency: "usd"}

If one fails, Cashier Service creates compensating transactions.
Ledger Service does not handle rollbacks.
```
*Note: Amounts are in cents (1000 = $10.00)*

## Technology Stack

- **Language**: Go
- **Database**: PostgreSQL
- **Communication**: REST over HTTP
- **Deployment**: Docker container

## Database Schema

```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(100) NOT NULL,
    amount BIGINT NOT NULL,
    currency VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_currency ON transactions(user_id, currency);
CREATE INDEX idx_created_at ON transactions(created_at);
```

**Note**: `amount` is stored as BIGINT to hold integer values representing the smallest currency unit (cents, centavos, pesos).

## API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /transactions | Create transaction |
| GET | /transactions | List user transactions |
| GET | /balance | Get user balance(s) |

See README.md for detailed API documentation.

## Folder Structure

```
ledger-service/
├── cmd/api/              # Application entry point
├── internal/
│   ├── handlers/         # HTTP request handlers
│   ├── models/           # Data structures
│   ├── repository/       # Database operations
│   └── validator/        # Input validation
├── migrations/           # Database schema versions
└── README.md
```

## Error Handling

- **400 Bad Request**: Malformed input (missing fields, invalid format, uppercase UUID)
- **500 Internal Server Error**: Database failures

No 404 errors - empty results return empty arrays/zero balances.

## Scalability Considerations

**Current (10-20 users):**
- Single database instance
- Simple SELECT SUM queries
- No caching

**Future (if needed):**
- Read replicas for balance queries
- Caching layer for frequently accessed balances
- Pagination for transaction lists
- Date range filtering
- Partitioning by user_id or date

**Not needed now. Add when problems appear.**

## Design Decisions

### Why No Transaction Types (debit/credit)?
Using signed integer amounts (`-5000` for $50 debit, `+5000` for $50 credit) simplifies:
- Balance calculation: just `SUM(amount)`
- Code: no conditional logic
- Understanding: the number tells the story
- Integer storage prevents floating-point precision errors

### Why No Soft Deletes?
Financial records are immutable. Corrections use compensating transactions.

### Why No Foreign Keys to User Table?
Loose coupling. User management is external (Authentik). Ledger doesn't know or care if user exists.

### Why No Description/Metadata Field?
Single responsibility. Other services handle categorization, tagging, linking.

### Why REST Not gRPC?
Simplicity. HTTP is universally understood. No proto files to maintain.

## Testing Strategy

### Unit Tests
- Input validation logic
- Balance calculation logic
- Model serialization

### Integration Tests
- API endpoints with test database
- Transaction creation → balance verification
- Concurrent transaction handling

### Not Testing
- Calling service business logic
- User existence
- External authentication

## Monitoring

**Metrics to track:**
- Transaction creation rate
- Balance query latency
- Database connection pool usage
- Error rates by endpoint

**Logging:**
- All transactions created (user_id, amount, currency, timestamp)
- All errors with context
- No sensitive data (amounts are not sensitive in this context)

## Deployment

Single Docker container:
- Stateless application
- Connects to PostgreSQL
- Environment variables for config (DB connection, port)
- No persistent state in container

## Future Considerations

**NOT building now, might need later:**
- Pagination (when transaction lists grow large)
- Date range filtering (when history gets deep)
- Bulk transaction creation (for batch imports)
- Event emission (if other services need real-time notifications)
- Read replicas (when query load increases)

**Build these when they become actual problems, not before.**
