package validator

import (
	"testing"

	"github.com/JorgeSaicoski/ledger-service/internal/models"
	"github.com/stretchr/testify/assert"
)

// TestValidateTransactionRequest_Success tests valid transaction request
func TestValidateTransactionRequest_Success(t *testing.T) {
	validator := NewTransactionValidator()

	req := models.TransactionRequest{
		UserID:   "550e8400-e29b-41d4-a716-446655440000",
		Amount:   10050,
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
		Amount:   10050,
		Currency: "usd",
	}

	err := validator.ValidateTransactionRequest(req)
	assert.ErrorIs(t, err, ErrUserIDEmpty)
}

// TestValidateTransactionRequest_EmptyCurrency tests validation fails for empty currency
func TestValidateTransactionRequest_EmptyCurrency(t *testing.T) {
	validator := NewTransactionValidator()

	req := models.TransactionRequest{
		UserID:   "550e8400-e29b-41d4-a716-446655440000",
		Amount:   10050,
		Currency: "",
	}

	err := validator.ValidateTransactionRequest(req)
	assert.ErrorIs(t, err, ErrCurrencyEmpty)
}

// TestValidateTransactionRequest_NegativeAmount tests negative amounts are valid
func TestValidateTransactionRequest_NegativeAmount(t *testing.T) {
	validator := NewTransactionValidator()

	req := models.TransactionRequest{
		UserID:   "550e8400-e29b-41d4-a716-446655440000",
		Amount:   -5025,
		Currency: "usd",
	}

	err := validator.ValidateTransactionRequest(req)
	assert.NoError(t, err, "Negative amounts should be valid")
}

// TestValidateUserID_Valid tests valid user IDs
func TestValidateUserID_Valid(t *testing.T) {
	validator := NewTransactionValidator()

	validUserIDs := []string{
		"123e4567-e89b-12d3-a456-426614174000",
		"550e8400-e29b-41d4-a716-446655440000",
		"f47ac10b-58cc-4372-a567-0e02b2c3d479",
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

func TestInvalidUserID(t *testing.T) {
	validator := NewTransactionValidator()
	invalidUserID := []string{
		"not-a-uuid",
		"user123",
		"USER-456",
		"user_with_underscore",
	}
	for _, id := range invalidUserID {
		err := validator.validateUserID(id)
		assert.ErrorIs(t, err, ErrUserIDInvalid)
	}

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
		"USD",           // uppercase isn't allowed
		"us-dollar",     // hyphen isn't allowed
		"us dollar",     // space isn't allowed
		"usd!",          // special char isn't allowed
		"currency@2023", // special char isn't allowed
	}

	for _, currency := range invalidCurrencies {
		err := validator.validateCurrency(currency)
		assert.ErrorIs(t, err, ErrCurrencyInvalid, "Currency '%s' should be invalid", currency)
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
		"12345678123442341234123456789012",    // no hyphens
		"12345678-1234-4234-8234-12345678901", // too short
		"",                                    // empty
	}

	for _, uuid := range invalidUUIDs {
		err := validator.ValidateUUID(uuid)
		assert.ErrorIs(t, err, ErrUUIDInvalid, "UUID '%s' should be invalid", uuid)
	}
}

func TestValidateUserID_EdgeCases(t *testing.T) {
	validator := NewTransactionValidator()

	invalidUserIDs := []string{
		"550E8400-E29B-41D4-A716-446655440000",  // uppercase hex
		"550e8400e29b41d4a716446655440000",      // missing hyphens
		"550e8400-e29b-41d4-a716-44665544000",   // too short
		"550e8400-e29b-41d4-a716-4466554400000", // too long
		"550e8400-e29b-41d4-a716-44665544_000",  // invalid char
		"550e8400-e29b-41d4-a716-44665544-0000", // extra hyphen
		"g50e8400-e29b-41d4-a716-446655440000",  // non-hex char
		" 550e8400-e29b-41d4-a716-446655440000", // leading space
		"550e8400-e29b-41d4-a716-446655440000 ", // trailing space
	}

	for _, id := range invalidUserIDs {
		err := validator.validateUserID(id)
		assert.ErrorIs(t, err, ErrUserIDInvalid, "UserID '%s' should be invalid", id)
	}

	validUserIDs := []string{
		"ffffffff-ffff-ffff-ffff-ffffffffffff", // all f, valid
		"00000000-0000-0000-0000-000000000000", // all 0, valid
	}
	for _, id := range validUserIDs {
		err := validator.validateUserID(id)
		assert.NoError(t, err, "UserID '%s' should be valid", id)
	}
}

func TestValidateCurrency_EdgeCases(t *testing.T) {
	validator := NewTransactionValidator()

	invalidCurrencies := []string{
		" usd",                                 // leading space
		"usd ",                                 // trailing space
		" usd ",                                // leading/trailing space
		"Usd",                                  // mixed case
		"usd\n",                                // newline
		"usd\t",                                // tab
		"usd$",                                 // special char
		"usd€",                                 // non-ASCII
		"usd123456789012345678901234567890123", // 33 chars, invalid
	}

	for _, currency := range invalidCurrencies {
		err := validator.validateCurrency(currency)
		assert.ErrorIs(t, err, ErrCurrencyInvalid, "Currency '%s' should be invalid", currency)
	}

	// Test empty separately - it returns ErrCurrencyEmpty
	err := validator.validateCurrency("")
	assert.ErrorIs(t, err, ErrCurrencyEmpty, "Empty currency should return ErrCurrencyEmpty")

	validCurrencies := []string{
		"usd12345678901234567890123456789", // 32 chars total (3+29=32)
		"abc_123",                          // underscore allowed
	}
	for _, currency := range validCurrencies {
		err := validator.validateCurrency(currency)
		assert.NoError(t, err, "Currency '%s' should be valid", currency)
	}
}
