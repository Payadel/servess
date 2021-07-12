using System;
using System.Collections.Generic;
using ModelsValidation.ResultDetails;

namespace servess.MethodErrors {
    public class MissInputError : ArgumentValidationError {
        public MissInputError(KeyValuePair<string, string> modelError, string? title = "Missing input",
            string? message = null,
            Exception? exception = null, bool showDefaultMessageToUser = true, object? moreDetail = null) : base(
            modelError, title, message, exception, showDefaultMessageToUser, moreDetail) { }

        public MissInputError(IEnumerable<KeyValuePair<string, string>> modelErrors, string? title = "Missing input",
            string? message = null, Exception? exception = null, bool showDefaultMessageToUser = true,
            object? moreDetail = null) : base(modelErrors, title, message, exception, showDefaultMessageToUser,
            moreDetail) { }
    }
}