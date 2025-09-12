const EmailPaymentRegistry = artifacts.require("EmailPaymentRegistry");

module.exports = function (deployer) {
  deployer.deploy(EmailPaymentRegistry);
};
