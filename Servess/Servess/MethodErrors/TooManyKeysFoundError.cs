using System;
using System.Collections.Generic;
using ModelsValidation.ResultDetails;

namespace Servess.MethodErrors {
    public class TooManyKeysFoundError : ArgumentValidationError {
        public TooManyKeysFoundError(KeyValuePair<string, string> modelError, string? title = "Too Many Keys Found",
            string? message = null, Exception? exception = null, bool showDefaultMessageToUser = true,
            object? moreDetail = null) : base(modelError, title, message, exception, showDefaultMessageToUser,
            moreDetail) { }

        public TooManyKeysFoundError(IEnumerable<KeyValuePair<string, string>> modelErrors,
            string? title = "Too Many Keys Found",
            string? message = null, Exception? exception = null, bool showDefaultMessageToUser = true,
            object? moreDetail = null) : base(modelErrors, title, message, exception, showDefaultMessageToUser,
            moreDetail) { }
    }
}