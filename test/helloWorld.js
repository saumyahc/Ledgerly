const helloWorld = artifacts.require("HelloWorld");

contract("HelloWorld", () => {
    it("should deploy the contract and set the initial message", async () => {
        const instance = await helloWorld.deployed();
        const message = await instance.message();
        assert.equal(message, "hello world", "Initial message should be 'hello world'");
    });

    it("should update the message", async () => {
        const instance = await helloWorld.deployed();
        await instance.setMessage("new mess");
        const message = await instance.getMessage();
        assert.equal(message, "new message", "Updated message should be 'new message'");
    });

});