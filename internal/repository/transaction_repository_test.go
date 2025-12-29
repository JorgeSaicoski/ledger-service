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
	db := setupTestDB(t)
	defer cleanupTestDB(t)
	repo := NewPostgresTransactionRepository(db)

	req := models.TransactionRequest{
		UserID:   "user123",
		Amount:   -14250,
		Currency: "usd",
	}

	result, err := repo.Create(context.Background(), req)

	require.NoError(t, err)
	assert.NotEmpty(t, result)

	transaction, err := repo.GetByID(context.Background(), result)
	require.NoError(t, err)
	assert.Equal(t, "user123", transaction.UserID)
	assert.Equal(t, -14250, transaction.Amount)
	assert.Equal(t, "usd", transaction.Currency)
}

// TestCreate_DifferentCurrencies tests creating transactions with various currencies
func TestCreate_DifferentCurrencies(t *testing.T) {
	db := setupTestDB(t)
	defer cleanupTestDB(t)
	repo := NewPostgresTransactionRepository(db)

	testCurrencies := []string{"usd", "brl", "eur", "loyalty_points", "reward_tokens"}
	for _, currency := range testCurrencies {
		result, err := repo.Create(context.Background(), models.TransactionRequest{
			UserID:   "user123",
			Amount:   10050,
			Currency: currency,
		})
		require.NoError(t, err)
		assert.NotEmpty(t, result)
	}
	transactions, err := repo.ListByUser(context.Background(), "user123", nil, 10, 0)
	require.NoError(t, err)
	assert.Equal(t, len(testCurrencies), len(transactions))

	remainingCurrencies := make([]string, len(testCurrencies))
	copy(remainingCurrencies, testCurrencies)

	for _, transaction := range transactions {
		found := false
		for i, currency := range remainingCurrencies {
			if transaction.Currency == currency {
				remainingCurrencies = append(remainingCurrencies[:i], remainingCurrencies[i+1:]...)
				found = true
				break
			}
		}
		assert.True(t, found, "unexpected currency: %s", transaction.Currency)
	}

	assert.Empty(t, remainingCurrencies, "not all currencies were found in transactions")
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
	db := setupTestDB(t)
	defer cleanupTestDB(t)
	repo := NewPostgresTransactionRepository(db)

	userID, err := repo.GetByID(context.Background(), "550e8400-e29b-41d4-a716-446655440000")

	require.Error(t, err)
	assert.Equal(t, "no rows in result set", err.Error())
	assert.Nil(t, userID)
}

// TestListByUser_Success tests listing transactions for a user
func TestListByUser_Success(t *testing.T) {
	db := setupTestDB(t)
	defer cleanupTestDB(t)
	repo := NewPostgresTransactionRepository(db)

	transactionsValues := []int{1445, 495999, 2312, 10050, 20000, 30000, 1233}
	userID := "user123"
	currency := "usd"

	createTransactions(t, repo, userID, transactionsValues, []string{currency})

	transactions, err := repo.ListByUser(context.Background(), userID, &currency, 10, 0)
	require.NoError(t, err)
	assert.Equal(t, len(transactionsValues), len(transactions))
	// Verify transactions are ordered by timestamp DESC (newest first)
	for i := 0; i < len(transactions)-1; i++ {
		assert.True(t, transactions[i].Timestamp.After(transactions[i+1].Timestamp) ||
			transactions[i].Timestamp.Equal(transactions[i+1].Timestamp),
			"transactions should be ordered by timestamp DESC")
	}

	// Verify all expected amounts are present (order doesn't matter for amounts)
	actualAmounts := make(map[int]bool)
	for _, transaction := range transactions {
		actualAmounts[transaction.Amount] = true
	}

	for _, expectedAmount := range transactionsValues {
		assert.True(t, actualAmounts[expectedAmount], "expected amount %d not found", expectedAmount)
	}
}

// TestListByUser_WithCurrencyFilter tests listing with currency filter
func TestListByUser_WithCurrencyFilter(t *testing.T) {
	db := setupTestDB(t)
	defer cleanupTestDB(t)
	repo := NewPostgresTransactionRepository(db)

	transactionsValues := []int{1445, 495999, 2312, 10050, 20000, 30000, 1233}
	userID := "user123"
	currencyBrl := "brl"
	currencyUsd := "usd"

	// Create transactions alternating between USD and BRL
	createTransactions(t, repo, userID, transactionsValues, []string{currencyUsd, currencyBrl})

	transactionsBRL, err := repo.ListByUser(context.Background(), userID, &currencyBrl, 10, 0)
	require.NoError(t, err)
	for _, transaction := range transactionsBRL {
		assert.Equal(t, currencyBrl, transaction.Currency)
	}

	transactionsUSD, err := repo.ListByUser(context.Background(), userID, &currencyUsd, 10, 0)
	require.NoError(t, err)
	for _, transaction := range transactionsUSD {
		assert.Equal(t, currencyUsd, transaction.Currency)
		for _, transactionBRL := range transactionsBRL {
			assert.NotEqual(t, transaction.ID, transactionBRL.ID)
		}
	}
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

// setupTestDB creates a test database instance and clears existing data
func setupTestDB(t *testing.T) *pgxpool.Pool {
	t.Helper()
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://test:test123@localhost:5432/ledger_db_test?sslmode=disable"
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		t.Log("TEST_DATABASE_URL:")
		t.Log(dsn)
		t.Fatal("unable to connect to database:", err)
	}

	// Clear existing test data
	_, err = pool.Exec(context.Background(), "TRUNCATE TABLE transactions")
	if err != nil {
		pool.Close()
		t.Fatal("unable to truncate transactions table:", err)
	}

	testDB = pool
	return pool
}

// cleanupTestDB closes the database connection
func cleanupTestDB(t *testing.T) {
	t.Helper()
	if testDB != nil {
		testDB.Close()
	}
}

// createTransactions is a helper function to create multiple transactions for testing
// If currencies is empty, defaults to "usd"
// If currencies has one element, all transactions use that currency
// If currencies has multiple elements, transactions cycle through them
func createTransactions(t *testing.T, repo *PostgresTransactionRepository, userID string, amounts []int, currencies []string) {
	t.Helper()

	// Default to USD if no currency specified
	if len(currencies) == 0 {
		currencies = []string{"usd"}
	}

	for i, amount := range amounts {
		currency := currencies[i%len(currencies)]
		_, err := repo.Create(context.Background(), models.TransactionRequest{
			UserID:   userID,
			Amount:   amount,
			Currency: currency,
		})
		require.NoError(t, err)
	}
}
