// SDPX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Oracle {
	Request[] requests; // list of requests made to the contract
	uint256 currentId = 0; // increasing request id
	uint256 minQuorum = 2; // minimum number of responses to receive before declaring final result
	uint256 totalOracleCount = 3; // Hardcoded oracle count

	// defines a general api request
	struct Request {
		uint256 id; // request id
		string urlToQuery; // API url
		string attributeToFetch; // json attribute (key) to retrieve in the response
		string agreedValue; // value from key
		mapping(uint256 => string) answers; // answers provided by the oracles
		mapping(address => uint256) quorum; // oracles which will query the answer (1 = oracle hasn't voted, 2 = oracle has voted)
	}

	// event that triggers oracle outside of the blockchain
	event NewRequest(uint256 id, string urlToQuery, string attributeToFetch);

	// triggered when there's a consensus on the final result
	event UpdateRequest(
		uint256 id,
		string urlToQuery,
		string attributeToFetch,
		string agreedValue
	);

	function createRequest(
		string memory _urlToQuery,
		string memory _attributeToFetch
	) public {
		uint256 length = requests.length;
		requests.push();
		Request storage r = requests[length];
		r.id = currentId;
		r.urlToQuery = _urlToQuery;
		r.attributeToFetch = _attributeToFetch;
		r.agreedValue = "";

		// Hardcoded oracles address
		r.quorum[address(0x6c2339b46F41a06f09CA0051ddAD54D1e582bA77)] = 1;
		r.quorum[address(0xb5346CF224c02186606e5f89EACC21eC25398077)] = 1;
		r.quorum[address(0xa2997F1CA363D11a0a35bB1Ac0Ff7849bc13e914)] = 1;

		// launch an event to be detected by oracle outside of blockchain
		emit NewRequest(currentId, _urlToQuery, _attributeToFetch);

		// increase request id
		currentId++;
	}

	// called by the oracle to record its answer
	function updateRequest(uint256 _id, string memory _valueRetrieved)
		public
	{
		Request storage currRequest = requests[_id];

		// check if oracle is in the list of trusted oracles
		// and if the oracle hasn't voted yet
		if (currRequest.quorum[address(msg.sender)] == 1) {
			// marking that this address has voted
			currRequest.quorum[msg.sender] = 2;

			// iterate through "array" of answers until a position if free and save the retrueved value
			uint256 tmpI = 0;
			bool found = false;
			while (!found) {
				// find first empty slot
				if (bytes(currRequest.answers[tmpI]).length == 0) {
					found = true;
					currRequest.answers[tmpI] = _valueRetrieved;
				}
				tmpI++;
			}

			uint256 currentQuorum = 0;

			// iterate through oracle list and check if enough oracles(minimum quorum)
			// have voted the same answer has the current one
			for (uint256 i = 0; i < totalOracleCount; i++) {
				bytes memory a = bytes(currRequest.answers[i]);
				bytes memory b = bytes(_valueRetrieved);

				if (keccak256(a) == keccak256(b)) {
					currentQuorum++;
					if (currentQuorum >= minQuorum) {
						currRequest.agreedValue = _valueRetrieved;
						emit UpdateRequest(
							currRequest.id,
							currRequest.urlToQuery,
							currRequest.attributeToFetch,
							currRequest.agreedValue
						);
					}
				}
			}
		}
	}
}
