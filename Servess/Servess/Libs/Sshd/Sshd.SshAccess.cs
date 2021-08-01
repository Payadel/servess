using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using Servess.Attributes;

namespace Servess.Libs.Sshd {
    public static partial class Sshd {
        [Command("ssh-access", "Limit Users ssh access")]
        public class SshAccess {
            [Input("path", "p", "SSHD file path", nameof(Path), false)]
            public string? Path { get; set; }

            [Input("list-allow-users", "la",
                "Show users can access to ssh", nameof(ListAllowUsers), isRequired: false, hasValue: false)]
            public bool? ListAllowUsers { get; set; }

            [Input("list-deny-users", "ld",
                "Show users can't access to ssh", nameof(ListDenyUsers), isRequired: false, hasValue: false)]
            public bool? ListDenyUsers { get; set; }

            [Input("add-allow-user", "aa",
                "Add user to Allow access to ssh", nameof(AddAllowUser), isRequired: false)]
            public string? AddAllowUser { get; set; }

            [Input("remove-allow-user", "ra",
                "Remove user from allow access to ssh", nameof(RemoveAllowUser), isRequired: false)]
            public string? RemoveAllowUser { get; set; }

            [Input("add-deny-user", "ad",
                "Add user to deny access to ssh", nameof(AddDenyUser), isRequired: false)]
            public string? AddDenyUser { get; set; }

            [Input("remove-deny-user", "rd",
                "Remove user from deny access to ssh", nameof(RemoveDenyUser), isRequired: false)]
            public string? RemoveDenyUser { get; set; }


            [Input("separator", "s",
                "Separator char that separates names in input", nameof(NameSeparator), isRequired: false)]
            public char NameSeparator { get; set; } = ' ';

            private const string KeySeparator = " ";
            private const string CommentSign = "#";

            //TODO: Validate names
            //TODO: Refactor

            [Operator]
            public MethodResult<string> Operation() {
                const string allowUsersKey = "AllowUsers";
                const string denyUsersKey = "DenyUsers";
                var path = Path ?? ConfigFilePath;
                var resultAllowUsers = new List<string>();
                var resultDenyUsers = new List<string>();

                //Base Validations
                var addAllowUsers = AddAllowUser?.Split(NameSeparator).Distinct().ToList();
                var removeAllowUsers = RemoveAllowUser?.Split(NameSeparator).Distinct().ToList();
                if (Utility.HaveDuplicateItems(addAllowUsers, removeAllowUsers)) {
                    return MethodResult<string>.Fail(
                        new BadRequestError(message: "Add and Remove allow users have duplicate items."));
                }

                if (addAllowUsers is not null) {
                    resultAllowUsers.AddRange(addAllowUsers);
                }


                var addDenyUsers = AddDenyUser?.Split(NameSeparator).Distinct().ToList();
                var removeDenyUsers = RemoveDenyUser?.Split(NameSeparator).Distinct().ToList();
                if (Utility.HaveDuplicateItems(addDenyUsers, removeDenyUsers)) {
                    return MethodResult<string>.Fail(
                        new BadRequestError(message: "Add and Remove deny users have duplicate items."));
                }

                if (addDenyUsers is not null) {
                    resultDenyUsers.AddRange(addDenyUsers);
                }

                if (Utility.HaveDuplicateItems(addAllowUsers, addDenyUsers)) {
                    return MethodResult<string>.Fail(
                        new BadRequestError(message: "An user can't add to both allow and deny groups."));
                }

                if (!File.Exists(path)) {
                    return MethodResult<string>.Fail(new NotFoundError(title: "File Not Found",
                        message: $"Can't find {path}"));
                }
                /////////////////////////////////////////////////////////////////////////////////////////////

                var lines = File.ReadAllLines(path).ToList();
                using var fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite,
                    FileShare.Read);

                var allowUsersIndexMethodResult =
                    Utility.FindLineIndex(lines, allowUsersKey, KeySeparator, CommentSign);
                if (!allowUsersIndexMethodResult.IsSuccess) {
                    return MethodResult<string>.Fail(allowUsersIndexMethodResult.Detail);
                }

                var currentAllowUsersIndex = allowUsersIndexMethodResult.Value;

                var currentAllowUsersMethodResult = currentAllowUsersIndex > 0
                    ? Utility.GetValue(lines[currentAllowUsersIndex], allowUsersKey, KeySeparator, CommentSign)
                    : null;

                if (currentAllowUsersMethodResult is not null && !currentAllowUsersMethodResult.IsSuccess) {
                    return MethodResult<string>.Fail(currentAllowUsersMethodResult.Detail);
                }

                var currentAllowUsers = currentAllowUsersMethodResult?.Value.Split(" ").ToList();
                if (currentAllowUsers is not null) {
                    if (removeAllowUsers is not null) {
                        currentAllowUsers.RemoveAll(item => removeAllowUsers.Any(removeItem => removeItem == item));
                    }

                    resultAllowUsers.AddRange(currentAllowUsers);
                }

                //////////////////////////////////////////////
                var denyUsersIndexMethodResult =
                    Utility.FindLineIndex(lines, denyUsersKey, KeySeparator, CommentSign);
                if (!denyUsersIndexMethodResult.IsSuccess) {
                    return MethodResult<string>.Fail(denyUsersIndexMethodResult.Detail);
                }

                var currentDenyUsersIndex = denyUsersIndexMethodResult.Value;


                var currentDenyUsersMethodResult = currentDenyUsersIndex > 0
                    ? Utility.GetValue(lines[currentDenyUsersIndex], denyUsersKey, KeySeparator, CommentSign)
                    : null;
                if (currentDenyUsersMethodResult is not null && !currentDenyUsersMethodResult.IsSuccess) {
                    return MethodResult<string>.Fail(currentDenyUsersMethodResult.Detail);
                }

                var currentDenyUsers = currentDenyUsersMethodResult?.Value.Split(" ").ToList();
                if (currentDenyUsers is not null) {
                    if (removeDenyUsers is not null) {
                        currentDenyUsers.RemoveAll(item => removeDenyUsers.Any(removeItem => removeItem == item));
                    }

                    resultDenyUsers.AddRange(currentDenyUsers);
                }


                resultAllowUsers = resultAllowUsers.Distinct().ToList();
                if (!resultAllowUsers.IsNullOrEmpty() && !resultAllowUsers.Contains("root")) {
                    Console.WriteLine("Warning!");
                    Console.WriteLine(
                        "The root user isn't exist in allowed list. This setting may prevent root user to access ssh.");
                    Console.Write("Do you want add root user to allowed list? (y/n) (y is recommended): ");
                    var addRoot = Console.ReadLine();
                    if (addRoot?.ToLower() == "y") {
                        resultAllowUsers.Add("root");
                    }
                }

                var combinedAllowUsers = Utility.CombineList(resultAllowUsers, " ");
                var methodResult = Utility.AddOrUpdateKeyValue(lines, allowUsersKey,
                    combinedAllowUsers, KeySeparator, CommentSign,
                    currentAllowUsersIndex).OnSuccess(newLines => lines = newLines);
                if (!methodResult.IsSuccess) {
                    return MethodResult<string>.Fail(methodResult.Detail);
                }


                resultDenyUsers = resultDenyUsers.Distinct().ToList();
                var combinedDenyUsers = Utility.CombineList(resultDenyUsers, " ");
                methodResult = Utility.AddOrUpdateKeyValue(lines, denyUsersKey,
                    combinedDenyUsers, KeySeparator, CommentSign,
                    currentDenyUsersIndex).OnSuccess(newLines => lines = newLines);
                if (!methodResult.IsSuccess) {
                    return MethodResult<string>.Fail(methodResult.Detail);
                }


                fileStream.Close();

                var operation = MethodResult.Ok();
                if (AddAllowUser is not null || RemoveAllowUser is not null || AddDenyUser is not null ||
                    RemoveDenyUser is not null) {
                    operation = TryExtensions.Try(() => File.WriteAllLines(path, lines))
                        .OnSuccess(() => Console.WriteLine("Done."));
                }

                return operation.OnSuccess(() => {
                    if (ListAllowUsers is not null)
                        Console.WriteLine($"Allow Users: {combinedAllowUsers}");

                    if (ListDenyUsers is not null)
                        Console.WriteLine($"Deny Users: {combinedDenyUsers}");

                    return MethodResult<string>.Ok(null!);
                });
            }
        }
    }
}