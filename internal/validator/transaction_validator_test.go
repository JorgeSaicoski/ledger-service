package validator

import (
	"math"
	"testing"

	"github.com/bardockgaucho/ledger-service/internal/models"
	"github.com/stretchr/testify/assert"
)

// TestValidateTransactionRequest_Success tests valid transaction request
func TestValidateTransactionRequest_Success(t *testing.T) {
	validator := NewTransactionValidator()

	req := models.TransactionRequest{
		UserID:   "user123",
		Amount:   100.50,
		Currency: "usd",
	}

	err := validator.ValidateTransactionRequest(req)
	assert.NoError(t, err)
}

// TestValidateTransactionRequest_EmptyUserID tests validation fails for empty user_id
func TestValidateTransactionRequest_EmptyUserID(t *testing.T) {
	validator := NewTransactionValidator()

	req := models.TransactionRequest{
		UserID:   "",
		Amount:   100.50,
		Currency: "usd",
	}

	err := validator.ValidateTransactionRequest(req)
	assert.ErrorIs(t, err, ErrUserIDEmpty)
}

// TestValidateTransactionRequest_EmptyCurrency tests validation fails for empty currency
func TestValidateTransactionRequest_EmptyCurrency(t *testing.T) {
	validator := NewTransactionValidator()

	req := models.TransactionRequest{
		UserID:   "user123",
		Amount:   100.50,
		Currency: "",
	}

	err := validator.ValidateTransactionRequest(req)
	assert.ErrorIs(t, err, ErrCurrencyEmpty)
}

// TestValidateTransactionRequest_NegativeAmount tests negative amounts are valid
func TestValidateTransactionRequest_NegativeAmount(t *testing.T) {
	validator := NewTransactionValidator()

	req := models.TransactionRequest{
		UserID:   "user123",
		Amount:   -50.25,
		Currency: "usd",
	}

	err := validator.ValidateTransactionRequest(req)
	assert.NoError(t, err, "Negative amounts should be valid")
}

// TestValidateUserID_Valid tests valid user IDs
func TestValidateUserID_Valid(t *testing.T) {
	validator := NewTransactionValidator()

	validUserIDs := []string{
		"user123",
		"USER-456",
		"user_with_underscore",
		"a1b2c3d4-e5f6-7890-abcd-ef1234567890", // UUID format
	}

	for _, userID := range validUserIDs {
		err := validator.validateUserID(userID)
		assert.NoError(t, err, "UserID '%s' should be valid", userID)
	}
}

// TestValidateUserID_Empty tests empty user ID fails
func TestValidateUserID_Empty(t *testing.T) {
	validator := NewTransactionValidator()

	err := validator.validateUserID("")
	assert.ErrorIs(t, err, ErrUserIDEmpty)
}

// TestValidateCurrency_Valid tests valid currency codes
func TestValidateCurrency_Valid(t *testing.T) {
	validator := NewTransactionValidator()

	validCurrencies := []string{
		"usd",
		"brl",
		"eur",
		"loyalty_points",
		"reward_tokens",
	}

	for _, currency := range validCurrencies {
		err := validator.validateCurrency(currency)
		assert.NoError(t, err, "Currency '%s' should be valid", currency)
	}
}

// TestValidateCurrency_Empty tests empty currency fails
func TestValidateCurrency_Empty(t *testing.T) {
	validator := NewTransactionValidator()

	err := validator.validateCurrency("")
	assert.ErrorIs(t, err, ErrCurrencyEmpty)
}

// TestValidateCurrency_TooLong tests currency exceeding max length fails
func TestValidateCurrency_TooLong(t *testing.T) {
	validator := NewTransactionValidator()

	// 33 characters - exceeds 32 char limit
	longCurrency := "this_is_a_very_long_currency_code"

	err := validator.validateCurrency(longCurrency)
	assert.ErrorIs(t, err, ErrCurrencyInvalid)
}

// TestValidateCurrency_InvalidCharacters tests invalid characters fail
func TestValidateCurrency_InvalidCharacters(t *testing.T) {
	validator := NewTransactionValidator()

	invalidCurrencies := []string{
		"USD",           // uppercase not allowed
		"us-dollar",     // hyphen not allowed
		"us dollar",     // space not allowed
		"usd!",          // special char not allowed
		"currency@2023", // special char not allowed
	}

	for _, currency := range invalidCurrencies {
		err := validator.validateCurrency(currency)
		assert.ErrorIs(t, err, ErrCurrencyInvalid, "Currency '%s' should be invalid", currency)
	}
}

// TestValidateAmount_Valid tests valid amounts
func TestValidateAmount_Valid(t *testing.T) {
	validator := NewTransactionValidator()

	validAmounts := []float64{
		100.50,
		-75.25,
		0,
		0.01,
		-0.01,
		999999.99,
	}

	for _, amount := range validAmounts {
		err := validator.validateAmount(amount)
		assert.NoError(t, err, "Amount %f should be valid", amount)
	}
}

// TestValidateAmount_Invalid tests invalid amounts
func TestValidateAmount_Invalid(t *testing.T) {
	validator := NewTransactionValidator()

	invalidAmounts := []float64{
		math.NaN(),
		math.Inf(1),
		math.Inf(-1),
	}

	for _, amount := range invalidAmounts {
		err := validator.validateAmount(amount)
		assert.ErrorIs(t, err, ErrAmountInvalid, "Amount %f should be invalid", amount)
	}
}

// TestValidateUUID_Valid tests valid UUID formats
func TestValidateUUID_Valid(t *testing.T) {
	validator := NewTransactionValidator()

	validUUIDs := []string{
		"a1b2c3d4-e5f6-4890-abcd-ef1234567890",
		"12345678-1234-4234-8234-123456789012",
		"00000000-0000-4000-8000-000000000000",
	}

	for _, uuid := range validUUIDs {
		err := validator.ValidateUUID(uuid)
		assert.NoError(t, err, "UUID '%s' should be valid", uuid)
	}
}

// TestValidateUUID_Invalid tests invalid UUID formats
func TestValidateUUID_Invalid(t *testing.T) {
	validator := NewTransactionValidator()

	invalidUUIDs := []string{
		"not-a-uuid",
		"12345678-1234-1234-1234-123456789012", // wrong version digit
		"12345678-1234-4234-1234-123456789012", // wrong variant digit
		"12345678123442341234123456789012",     // no hyphens
		"12345678-1234-4234-8234-12345678901",  // too short
		"",                                     // empty
	}

	for _, uuid := range invalidUUIDs {
		err := validator.ValidateUUID(uuid)
		assert.ErrorIs(t, err, ErrUUIDInvalid, "UUID '%s' should be invalid", uuid)
	}
}
