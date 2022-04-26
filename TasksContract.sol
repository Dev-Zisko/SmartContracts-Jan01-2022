// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract TasksContract {

    uint256 public taskCounter = 0;

    constructor () {
        createTask("First Task", "I have to do something.");
    }

    event TaskCreated(
        uint256 id,
        string title,
        string description,
        bool done,
        uint256 created_at
    );

    event TaskToggleDone(
        uint256 id,
        bool done
    );

    struct Task {
        uint256 id;
        string title;
        string description;
        bool done;
        uint256 created_at;
    }

    mapping(uint256 => Task) public tasks;

    function createTask(string memory _title, string memory _description) public {
        taskCounter++;
        tasks[taskCounter] = Task(taskCounter, _title, _description, false, block.timestamp);
        emit TaskCreated(taskCounter, _title, _description, false,  block.timestamp);
    }

    function toggleDone(uint256 _id) public {
        Task memory _task = tasks[_id];
        _task.done = !_task.done;
        tasks[_id] = _task;
        emit TaskToggleDone(_id, _task.done);
    }

    function deleteTask() public {

    }
}