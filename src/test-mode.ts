let _testMode = false;

export function getTestMode(): boolean {
	return _testMode;
}

export function setTestMode(value: boolean): void {
	_testMode = value;
}
