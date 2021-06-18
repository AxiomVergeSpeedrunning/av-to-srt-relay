all: windows linux linux-arm macos macos-arm

linux: dir
	GOOS=linux GOARCH=amd64 go build -o bin/linux-x64.bin

linux-arm: dir
	GOOS=linux GOARCH=arm64 go build -o bin/linux-arm64.bin

windows: dir
	GOOS=windows GOARCH=amd64 go build -o bin/windows-x64.exe

macos: dir
	GOOS=darwin GOARCH=arm64 go build -o bin/macos-x64.exe

macos-arm: dir
	GOOS=darwin GOARCH=arm64 go build -o bin/macos-arm64.exe

dir:
	mkdir -p bin
