output=$1
slnPath=./Servess/

sudo dotnet publish -c Release -r linux-x64 --self-contained false -o $output $slnPath
