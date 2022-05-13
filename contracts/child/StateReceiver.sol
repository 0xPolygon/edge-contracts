// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


// Bridge is the proxy that calls the specific bridge contracts
contract StateReceiver {
    // Maxium gas state sync use
    uint256 public constant MAX_GAS = 300000;
    // Index of the next event which needs to be processed.
    uint256 public counter;

    // 0=success, 1=failure, 2=skip
    enum ResultStatus {
        SUCCESS,
        FAILURE,
        SKIP
    }

    event ResultEvent(
        uint256 indexed counter,
        ResultStatus indexed status,
        bytes extra
    );

    function stateSync (
        uint256 id,
        address sender,
        address receiver,
        bytes calldata data,
        bool skip,
        bytes memory /*signature*/
    ) public payable {
        // validate state id order
        require(counter + 1 == id, "ID_NOT_SEQUENTIAL");

        // increament the counter
        counter++;

        //
        // TODO check the signatures before processing anything below
        // TODO Validate signature parameter. Signature must be present in current validator set.
        //

        // Skip transaction if necessary
        if (skip) {
            emit ResultEvent(id, ResultStatus.SKIP, "");
            return;
        }


        // Execute onStateReceive method on target using max gas limit
        uint256 txGas = MAX_GAS;
        bool success = false;
        bytes memory paramData = abi.encodeWithSignature(
            "onStateReceive(uint64,address,bytes)",
            id,
            sender,
            data
        );
        assembly {
            success := call(
                txGas,
                receiver,
                0,
                add(paramData, 0x20),
                mload(paramData),
                0,
                0
            )
        }

        // emit a ResultEvent indicating whether invocation of bridge was successful or not
        if (success) {
            emit ResultEvent(counter, ResultStatus.SUCCESS, "");
        } else {
            emit ResultEvent(counter, ResultStatus.FAILURE, "");
        }
    }
}
