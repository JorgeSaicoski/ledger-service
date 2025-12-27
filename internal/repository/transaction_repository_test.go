package repository

import (
	"context"
	"os"
	"testing"

	"github.com/bardockgaucho/ledger-service/internal/models"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var testDB *pgxpool.Pool

// TestCreate_Success tests successful transaction creation
func TestCreate_Success(t *testing.T) {
	db := setupTestDB(t)
	defer cleanupTestDB(t)
	repo := NewPostgresTransactionRepository(db)

	req := models.TransactionRequest{
		UserID:   "user123",
		Amount:   10050,
		Currency: "usd",
	}

	result, err := repo.Create(context.Background(), req)

	require.NoError(t, err)
	assert.NotEmpty(t, result)

	transaction, err := repo.GetByID(context.Background(), result)
	require.NoError(t, err)
	assert.Equal(t, "user123", transaction.UserID)
	assert.Equal(t, 10050, transaction.Amount)
	assert.Equal(t, "usd", transaction.Currency)
}

// TestCreate_NegativeAmount tests creating transaction with negative amount
func TestCreate_NegativeAmount(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Test that negative amounts are properly stored
	// req := models.TransactionRequest{
	// 	UserID:   "user456",
	// 	Amount:   -75.25,
	// 	Currency: "usd",
	// }

	// result, err := repo.Create(context.Background(), req)
	// require.NoError(t, err)
	// assert.Equal(t, -75.25, result.Amount)
}

// TestCreate_DifferentCurrencies tests creating transactions with various currencies
func TestCreate_DifferentCurrencies(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Test multiple currency types: usd, brl, loyalty_points
}

// TestGetByID_Success tests retrieving an existing transaction
func TestGetByID_Success(t *testing.T) {
	db := setupTestDB(t)
	defer cleanupTestDB(t)
	repo := NewPostgresTransactionRepository(db)

	req := models.TransactionRequest{
		UserID:   "user123",
		Amount:   10050,
		Currency: "usd",
	}

	result, err := repo.Create(context.Background(), req)
	require.NoError(t, err)

	transaction, err := repo.GetByID(context.Background(), result)
	require.NoError(t, err)
	assert.Equal(t, req.UserID, transaction.UserID)
	assert.Equal(t, req.Amount, transaction.Amount)
	assert.Equal(t, req.Currency, transaction.Currency)
}

// TestGetByID_NotFound tests retrieving a non-existent transaction
func TestGetByID_NotFound(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Try to get a transaction with non-existent UUID
	// Should return sql.ErrNoRows or custom not found error
}

// TestGetByID_InvalidUUID tests retrieving with malformed UUID
func TestGetByID_InvalidUUID(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Pass invalid UUID format
	// Should return validation error
}

// TestListByUser_Success tests listing transactions for a user
func TestListByUser_Success(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create multiple transactions for user123
	// List them
	// Verify count and order (newest first)
}

// TestListByUser_WithCurrencyFilter tests listing with currency filter
func TestListByUser_WithCurrencyFilter(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create transactions in USD and BRL
	// Filter by USD only
	// Verify only USD transactions returned
}

// TestListByUser_WithPagination tests pagination parameters
func TestListByUser_WithPagination(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create 5 transactions
	// Request with limit=2, offset=0 -> should get first 2
	// Request with limit=2, offset=2 -> should get next 2
}

// TestListByUser_OrderByTimestampDesc tests ordering
func TestListByUser_OrderByTimestampDesc(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create transactions with delays to ensure different timestamps
	// Verify newest comes first
}

// TestListByUser_EmptyResult tests listing for user with no transactions
func TestListByUser_EmptyResult(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// List transactions for non-existent user
	// Should return empty array, not error
}

// TestGetBalance_SingleCurrency tests balance calculation
func TestGetBalance_SingleCurrency(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create transactions: +100, -30, +50
	// Balance should be 120
}

// TestGetBalance_NegativeBalance tests negative balance
func TestGetBalance_NegativeBalance(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create transactions: -50, -25
	// Balance should be -75
}

// TestGetBalance_IntegerPrecision tests integer calculation accuracy
func TestGetBalance_IntegerPrecision(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create transactions with integer amounts: 9999, 2576, -1050 (representing $99.99, $25.76, -$10.50 in cents)
	// Verify precise calculation: 11525 (representing $115.25)
}

// TestGetBalance_NoTransactions tests balance with no transactions
func TestGetBalance_NoTransactions(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Get balance for user with no transactions
	// Should return 0, not error
}

// TestGetAllBalances_MultipleCurrencies tests multi-currency balances
func TestGetAllBalances_MultipleCurrencies(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Create transactions in USD, BRL, loyalty_points
	// Verify balances returned for all three currencies
}

// TestGetAllBalances_EmptyResult tests all balances with no transactions
func TestGetAllBalances_EmptyResult(t *testing.T) {
	t.Skip("Implement after setting up test database")

	// Get all balances for user with no transactions
	// Should return empty array, not error
}

// Helper functions that will be implemented

// setupTestDB creates a test database instance
func setupTestDB(t *testing.T) *pgxpool.Pool {
	// TODO: Create test database connection
	// TODO: Run migrations
	// Explain why t.Helper() is needed
	// See https://pkg.go.dev/testing#T.Helper
	t.Helper()
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://test:test123@localhost:5432/ledger_db_test?sslmode=disable"
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		// log the dsn that is not working
		t.Log("TEST_DATABASE_URL:")
		t.Log(dsn)
		t.Fatal("unable to connect to database:", err)
	}
	testDB = pool
	return pool
}

// cleanupTestDB cleans up test database
func cleanupTestDB(t *testing.T) {
	t.Helper()
	if testDB != nil {
		testDB.Close()
	}
}
