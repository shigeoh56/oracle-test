// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Counter is KeeperCompatible {
	// public counter variable
	uint256 public counter;

	// Use and interval in seconds and a timestamp to slow execution of Upkeep
	uint256 public immutable interval;
	uint256 public lastTimeStamp;

	constructor(uint256 updateInterval) {
		interval = updateInterval;
		lastTimeStamp = block.timestamp;

		counter = 0;
	}

	function checkUpkeep(
		bytes calldata /* checkData */
	)
		external
		view
		override
		returns (
			bool upkeepNeeded,
			bytes memory /* performData */
		)
	{
		upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
	}

	function performUpkeep(
		bytes calldata /* performData */
	) external override {
		lastTimeStamp = block.timestamp;
		counter = counter + 1;
		// We don't use the performData in this example.
		// The performData is generated by the keeper's call to your checkUpkeep function
	}
}