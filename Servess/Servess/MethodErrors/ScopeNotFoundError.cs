using System;
using FunctionalUtility.ResultDetails.Errors;

namespace servess.MethodErrors {
    public class ScopeNotFoundError : NotFoundError {
        public ScopeNotFoundError(string? title = "Scope Not Found", string? message = null, Exception? exception = null,
            bool showDefaultMessageToUser = true, object? moreDetails = null) : base(title, message, exception,
            showDefaultMessageToUser, moreDetails) { }
    }
}