output=$1
slnPath=$2

dotnet publish -c Release -r linux-x64 --self-contained false -o $output $slnPath
