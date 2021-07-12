using System;
using FunctionalUtility.ResultDetails.Errors;

namespace servess.MethodErrors {
    public class CommandNotFoundError : NotFoundError {
        public CommandNotFoundError(string? title = "Command Not Found", string? message = null,
            Exception? exception = null,
            bool showDefaultMessageToUser = true, object? moreDetails = null) : base(title, message, exception,
            showDefaultMessageToUser, moreDetails) { }
    }
}