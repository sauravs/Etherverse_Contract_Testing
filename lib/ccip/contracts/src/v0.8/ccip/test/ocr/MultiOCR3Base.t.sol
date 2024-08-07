// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {MultiOCR3Base} from "../../ocr/MultiOCR3Base.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {MultiOCR3Helper} from "../helpers/MultiOCR3Helper.sol";

import {Vm} from "forge-std/Vm.sol";

contract MultiOCR3BaseSetup is BaseTest {
  // Signer private keys used for these test
  uint256 internal constant PRIVATE0 = 0x7b2e97fe057e6de99d6872a2ef2abf52c9b4469bc848c2465ac3fcd8d336e81d;

  address[] internal s_validSigners;
  address[] internal s_validTransmitters;
  uint256[] internal s_validSignerKeys;

  address[] internal s_partialSigners;
  address[] internal s_partialTransmitters;
  uint256[] internal s_partialSignerKeys;

  address[] internal s_emptySigners;

  bytes internal constant REPORT = abi.encode("testReport");
  MultiOCR3Helper internal s_multiOCR3;

  function setUp() public virtual override {
    BaseTest.setUp();

    uint160 numSigners = 7;
    s_validSignerKeys = new uint256[](numSigners);
    s_validSigners = new address[](numSigners);
    s_validTransmitters = new address[](numSigners);

    for (uint160 i; i < numSigners; ++i) {
      s_validTransmitters[i] = address(4 + i);
      s_validSignerKeys[i] = PRIVATE0 + i;
      s_validSigners[i] = vm.addr(s_validSignerKeys[i]);
    }

    s_partialSigners = new address[](4);
    s_partialSignerKeys = new uint256[](4);
    s_partialTransmitters = new address[](4);
    for (uint256 i; i < s_partialSigners.length; ++i) {
      s_partialSigners[i] = s_validSigners[i];
      s_partialSignerKeys[i] = s_validSignerKeys[i];
      s_partialTransmitters[i] = s_validTransmitters[i];
    }

    s_emptySigners = new address[](0);

    s_multiOCR3 = new MultiOCR3Helper();
  }

  /// @dev returns a mock config digest with config digest computation logic similar to OCR2Base
  function _getBasicConfigDigest(
    uint8 F,
    address[] memory signers,
    address[] memory transmitters
  ) internal view returns (bytes32) {
    bytes memory configBytes = abi.encode("");
    uint256 configVersion = 1;

    uint256 h = uint256(
      keccak256(
        abi.encode(
          block.chainid, address(s_multiOCR3), signers, transmitters, F, configBytes, configVersion, configBytes
        )
      )
    );
    uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
    uint256 prefix = 0x0001 << (256 - 16); // 0x000100..00
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  /// @dev returns a hash value in the same format as the h value on which the signature verified
  ///      in the _transmit function
  function _getTestReportDigest(bytes32 configDigest) internal pure returns (bytes32) {
    bytes32[3] memory reportContext = [configDigest, configDigest, configDigest];
    return keccak256(abi.encodePacked(keccak256(REPORT), reportContext));
  }

  function _assertOCRConfigEquality(
    MultiOCR3Base.OCRConfig memory configA,
    MultiOCR3Base.OCRConfig memory configB
  ) internal pure {
    vm.assertEq(configA.configInfo.configDigest, configB.configInfo.configDigest);
    vm.assertEq(configA.configInfo.F, configB.configInfo.F);
    vm.assertEq(configA.configInfo.n, configB.configInfo.n);
    vm.assertEq(configA.configInfo.uniqueReports, configB.configInfo.uniqueReports);
    vm.assertEq(configA.configInfo.isSignatureVerificationEnabled, configB.configInfo.isSignatureVerificationEnabled);

    vm.assertEq(configA.signers, configB.signers);
    vm.assertEq(configA.transmitters, configB.transmitters);
  }

  function _assertOCRConfigUnconfigured(MultiOCR3Base.OCRConfig memory config) internal pure {
    assertEq(config.configInfo.configDigest, bytes32(""));
    assertEq(config.signers.length, 0);
    assertEq(config.transmitters.length, 0);
  }

  function _getSignaturesForDigest(
    uint256[] memory signerPrivateKeys,
    bytes32 configDigest,
    uint8 signatureCount
  ) internal pure returns (bytes32[] memory rs, bytes32[] memory ss, uint8[] memory vs, bytes32 rawVs) {
    rs = new bytes32[](signatureCount);
    ss = new bytes32[](signatureCount);
    vs = new uint8[](signatureCount);

    // Calculate signatures
    for (uint256 i; i < signatureCount; ++i) {
      (vs[i], rs[i], ss[i]) = vm.sign(signerPrivateKeys[i], _getTestReportDigest(configDigest));
      rawVs = rawVs | (bytes32(bytes1(vs[i] - 27)) >> (8 * i));
    }

    return (rs, ss, vs, rawVs);
  }
}

contract MultiOCR3Base_transmit is MultiOCR3BaseSetup {
  bytes32 internal s_configDigest1;
  bytes32 internal s_configDigest2;
  bytes32 internal s_configDigest3;

  function setUp() public virtual override {
    super.setUp();

    s_configDigest1 = _getBasicConfigDigest(1, s_validSigners, s_validTransmitters);
    s_configDigest2 = _getBasicConfigDigest(1, s_validSigners, s_validTransmitters);
    s_configDigest3 = _getBasicConfigDigest(2, s_emptySigners, s_validTransmitters);

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](3);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: s_configDigest1,
      F: 1,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });
    ocrConfigs[1] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 1,
      configDigest: s_configDigest2,
      F: 2,
      uniqueReports: true,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });
    ocrConfigs[2] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 2,
      configDigest: s_configDigest3,
      F: 1,
      uniqueReports: false,
      isSignatureVerificationEnabled: false,
      signers: s_emptySigners,
      transmitters: s_validTransmitters
    });

    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_TransmitSignersNonUniqueReports_gas_Success() public {
    vm.pauseGasMetering();
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    // F = 2, need 2 signatures
    (bytes32[] memory rs, bytes32[] memory ss,, bytes32 rawVs) =
      _getSignaturesForDigest(s_validSignerKeys, s_configDigest1, 2);

    s_multiOCR3.setTransmitOcrPluginType(0);

    vm.expectEmit();
    emit MultiOCR3Base.Transmitted(0, s_configDigest1, uint32(uint256(s_configDigest1) >> 8));

    vm.startPrank(s_validTransmitters[1]);
    vm.resumeGasMetering();
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  function test_TransmitUniqueReportSigners_gas_Success() public {
    vm.pauseGasMetering();
    bytes32[3] memory reportContext = [s_configDigest2, s_configDigest2, s_configDigest2];

    // F = 1, need 5 signatures
    (bytes32[] memory rs, bytes32[] memory ss,, bytes32 rawVs) =
      _getSignaturesForDigest(s_validSignerKeys, s_configDigest2, 5);

    s_multiOCR3.setTransmitOcrPluginType(1);

    vm.expectEmit();
    emit MultiOCR3Base.Transmitted(1, s_configDigest2, uint32(uint256(s_configDigest2) >> 8));

    vm.startPrank(s_validTransmitters[2]);
    vm.resumeGasMetering();
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  function test_TransmitWithoutSignatureVerification_gas_Success() public {
    vm.pauseGasMetering();
    bytes32[3] memory reportContext = [s_configDigest3, s_configDigest3, s_configDigest3];

    s_multiOCR3.setTransmitOcrPluginType(2);

    vm.expectEmit();
    emit MultiOCR3Base.Transmitted(2, s_configDigest3, uint32(uint256(s_configDigest3) >> 8));

    vm.startPrank(s_validTransmitters[0]);
    vm.resumeGasMetering();
    s_multiOCR3.transmitWithoutSignatures(reportContext, REPORT);
  }

  function test_Fuzz_TransmitSignersWithSignatures_Success(
    uint8 F,
    uint64 randomAddressOffset,
    bool uniqueReports
  ) public {
    vm.pauseGasMetering();

    F = uint8(bound(F, 1, 3));

    // condition: signers.length > 3F
    uint8 signersLength = 3 * F + 1;
    address[] memory signers = new address[](signersLength);
    address[] memory transmitters = new address[](signersLength);
    uint256[] memory signerKeys = new uint256[](signersLength);

    // Force addresses to be unique (with a random offset for broader testing)
    for (uint160 i = 0; i < signersLength; ++i) {
      transmitters[i] = vm.addr(PRIVATE0 + randomAddressOffset + i);
      // condition: non-zero oracle address
      vm.assume(transmitters[i] != address(0));

      // condition: non-repeating addresses (no clashes with transmitters)
      signerKeys[i] = PRIVATE0 + randomAddressOffset + i + signersLength;
      signers[i] = vm.addr(signerKeys[i]);
      vm.assume(signers[i] != address(0));
    }

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 3,
      configDigest: s_configDigest1,
      F: F,
      uniqueReports: uniqueReports,
      isSignatureVerificationEnabled: true,
      signers: signers,
      transmitters: transmitters
    });
    s_multiOCR3.setOCR3Configs(ocrConfigs);
    s_multiOCR3.setTransmitOcrPluginType(3);

    // Randomise picked transmitter with random offset
    vm.startPrank(transmitters[randomAddressOffset % signersLength]);

    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    // condition: matches signature expectation for transmit
    uint8 numSignatures = uniqueReports ? ((signersLength + F) / 2 + 1) : (F + 1);
    uint256[] memory pickedSignerKeys = new uint256[](numSignatures);

    // Randomise picked signers with random offset
    for (uint256 i; i < numSignatures; ++i) {
      pickedSignerKeys[i] = signerKeys[(i + randomAddressOffset) % numSignatures];
    }

    (bytes32[] memory rs, bytes32[] memory ss,, bytes32 rawVs) =
      _getSignaturesForDigest(pickedSignerKeys, s_configDigest1, numSignatures);

    vm.expectEmit();
    emit MultiOCR3Base.Transmitted(3, s_configDigest1, uint32(uint256(s_configDigest1) >> 8));

    vm.resumeGasMetering();
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  // Reverts
  function test_ForkedChain_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    (bytes32[] memory rs, bytes32[] memory ss,, bytes32 rawVs) =
      _getSignaturesForDigest(s_validSignerKeys, s_configDigest1, 2);

    s_multiOCR3.setTransmitOcrPluginType(0);

    uint256 chain1 = block.chainid;
    uint256 chain2 = chain1 + 1;
    vm.chainId(chain2);
    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.ForkedChain.selector, chain1, chain2));

    vm.startPrank(s_validTransmitters[0]);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  function test_ZeroSignatures_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    s_multiOCR3.setTransmitOcrPluginType(0);

    vm.startPrank(s_validTransmitters[0]);
    vm.expectRevert(MultiOCR3Base.WrongNumberOfSignatures.selector);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, new bytes32[](0), new bytes32[](0), bytes32(""));
  }

  function test_TooManySignatures_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    // 1 signature too many
    (bytes32[] memory rs, bytes32[] memory ss,, bytes32 rawVs) =
      _getSignaturesForDigest(s_validSignerKeys, s_configDigest2, 6);

    s_multiOCR3.setTransmitOcrPluginType(1);

    vm.startPrank(s_validTransmitters[0]);
    vm.expectRevert(MultiOCR3Base.WrongNumberOfSignatures.selector);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  function test_InsufficientSignatures_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    // Missing 1 signature for unique report
    (bytes32[] memory rs, bytes32[] memory ss,, bytes32 rawVs) =
      _getSignaturesForDigest(s_validSignerKeys, s_configDigest2, 4);

    s_multiOCR3.setTransmitOcrPluginType(1);

    vm.startPrank(s_validTransmitters[0]);
    vm.expectRevert(MultiOCR3Base.WrongNumberOfSignatures.selector);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  function test_ConfigDigestMismatch_Revert() public {
    bytes32 configDigest;
    bytes32[3] memory reportContext = [configDigest, configDigest, configDigest];

    (,,, bytes32 rawVs) = _getSignaturesForDigest(s_validSignerKeys, s_configDigest1, 2);

    s_multiOCR3.setTransmitOcrPluginType(0);

    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.ConfigDigestMismatch.selector, s_configDigest1, configDigest));
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, new bytes32[](0), new bytes32[](0), rawVs);
  }

  function test_SignatureOutOfRegistration_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    bytes32[] memory rs = new bytes32[](2);
    bytes32[] memory ss = new bytes32[](1);

    s_multiOCR3.setTransmitOcrPluginType(0);

    vm.startPrank(s_validTransmitters[0]);
    vm.expectRevert(MultiOCR3Base.SignaturesOutOfRegistration.selector);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, bytes32(""));
  }

  function test_UnAuthorizedTransmitter_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];
    bytes32[] memory rs = new bytes32[](2);
    bytes32[] memory ss = new bytes32[](2);

    s_multiOCR3.setTransmitOcrPluginType(0);

    vm.expectRevert(MultiOCR3Base.UnauthorizedTransmitter.selector);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, bytes32(""));
  }

  function test_NonUniqueSignature_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    (bytes32[] memory rs, bytes32[] memory ss, uint8[] memory vs, bytes32 rawVs) =
      _getSignaturesForDigest(s_validSignerKeys, s_configDigest1, 2);

    rs[1] = rs[0];
    ss[1] = ss[0];
    // Need to reset the rawVs to be valid
    rawVs = bytes32(bytes1(vs[0] - 27)) | (bytes32(bytes1(vs[0] - 27)) >> 8);

    s_multiOCR3.setTransmitOcrPluginType(0);

    vm.startPrank(s_validTransmitters[0]);
    vm.expectRevert(MultiOCR3Base.NonUniqueSignatures.selector);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  function test_UnauthorizedSigner_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    (bytes32[] memory rs, bytes32[] memory ss,, bytes32 rawVs) =
      _getSignaturesForDigest(s_validSignerKeys, s_configDigest1, 2);

    rs[0] = s_configDigest1;
    ss = rs;

    s_multiOCR3.setTransmitOcrPluginType(0);

    vm.startPrank(s_validTransmitters[0]);
    vm.expectRevert(MultiOCR3Base.UnauthorizedSigner.selector);
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, rawVs);
  }

  function test_UnconfiguredPlugin_Revert() public {
    bytes32 configDigest;
    bytes32[3] memory reportContext = [configDigest, configDigest, configDigest];

    s_multiOCR3.setTransmitOcrPluginType(42);

    vm.expectRevert(MultiOCR3Base.UnauthorizedTransmitter.selector);
    s_multiOCR3.transmitWithoutSignatures(reportContext, REPORT);
  }

  function test_TransmitWithLessCalldataArgs_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];

    s_multiOCR3.setTransmitOcrPluginType(0);

    // The transmit should fail, since we are trying to transmit without signatures when signatures are enabled
    vm.startPrank(s_validTransmitters[1]);

    // report length + function selector + report length + abiencoded location of report value + report context words
    uint256 receivedLength = REPORT.length + 4 + 5 * 32;
    vm.expectRevert(
      abi.encodeWithSelector(
        MultiOCR3Base.WrongMessageLength.selector,
        // Expecting inclusion of signature constant length components
        receivedLength + 5 * 32,
        receivedLength
      )
    );
    s_multiOCR3.transmitWithoutSignatures(reportContext, REPORT);
  }

  function test_TransmitWithExtraCalldataArgs_Revert() public {
    bytes32[3] memory reportContext = [s_configDigest1, s_configDigest1, s_configDigest1];
    bytes32[] memory rs = new bytes32[](2);
    bytes32[] memory ss = new bytes32[](2);

    s_multiOCR3.setTransmitOcrPluginType(2);

    // The transmit should fail, since we are trying to transmit with signatures when signatures are disabled
    vm.startPrank(s_validTransmitters[1]);

    // dynamic length + function selector + report length + abiencoded location of report value + report context words
    // rawVs value, lengths of rs, ss, and start locations of rs & ss -> 5 words
    uint256 receivedLength = REPORT.length + 4 + (5 * 32) + (5 * 32) + (2 * 32) + (2 * 32);
    vm.expectRevert(
      abi.encodeWithSelector(
        MultiOCR3Base.WrongMessageLength.selector,
        // Expecting exclusion of signature constant length components and rs, ss words
        receivedLength - (5 * 32) - (4 * 32),
        receivedLength
      )
    );
    s_multiOCR3.transmitWithSignatures(reportContext, REPORT, rs, ss, bytes32(""));
  }
}

contract MultiOCR3Base_setOCR3Configs is MultiOCR3BaseSetup {
  function test_SetConfigsZeroInput_Success() public {
    vm.recordLogs();
    s_multiOCR3.setOCR3Configs(new MultiOCR3Base.OCRConfigArgs[](0));

    // No logs emitted
    Vm.Log[] memory logEntries = vm.getRecordedLogs();
    assertEq(logEntries.length, 0);
  }

  function test_SetConfigWithSigners_Success() public {
    uint8 F = 2;

    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(0));

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(F, s_validSigners, s_validTransmitters),
      F: F,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });

    vm.expectEmit();
    emit MultiOCR3Base.ConfigSet(
      ocrConfigs[0].ocrPluginType,
      ocrConfigs[0].configDigest,
      ocrConfigs[0].signers,
      ocrConfigs[0].transmitters,
      ocrConfigs[0].F
    );
    s_multiOCR3.setOCR3Configs(ocrConfigs);

    MultiOCR3Base.OCRConfig memory expectedConfig = MultiOCR3Base.OCRConfig({
      configInfo: MultiOCR3Base.ConfigInfo({
        configDigest: ocrConfigs[0].configDigest,
        F: ocrConfigs[0].F,
        n: uint8(s_validSigners.length),
        uniqueReports: ocrConfigs[0].uniqueReports,
        isSignatureVerificationEnabled: ocrConfigs[0].isSignatureVerificationEnabled
      }),
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });
    _assertOCRConfigEquality(s_multiOCR3.latestConfigDetails(0), expectedConfig);
  }

  function test_SetConfigWithoutSigners_Success() public {
    uint8 F = 1;
    address[] memory signers = new address[](0);

    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(0));

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(F, signers, s_validTransmitters),
      F: F,
      uniqueReports: false,
      isSignatureVerificationEnabled: false,
      signers: signers,
      transmitters: s_validTransmitters
    });

    vm.expectEmit();
    emit MultiOCR3Base.ConfigSet(
      ocrConfigs[0].ocrPluginType,
      ocrConfigs[0].configDigest,
      ocrConfigs[0].signers,
      ocrConfigs[0].transmitters,
      ocrConfigs[0].F
    );
    s_multiOCR3.setOCR3Configs(ocrConfigs);

    MultiOCR3Base.OCRConfig memory expectedConfig = MultiOCR3Base.OCRConfig({
      configInfo: MultiOCR3Base.ConfigInfo({
        configDigest: ocrConfigs[0].configDigest,
        F: ocrConfigs[0].F,
        n: uint8(s_validTransmitters.length),
        uniqueReports: ocrConfigs[0].uniqueReports,
        isSignatureVerificationEnabled: ocrConfigs[0].isSignatureVerificationEnabled
      }),
      signers: signers,
      transmitters: s_validTransmitters
    });
    _assertOCRConfigEquality(s_multiOCR3.latestConfigDetails(0), expectedConfig);
  }

  function test_SetMultipleConfigs_Success() public {
    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(0));
    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(1));
    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(2));

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](3);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(2, s_validSigners, s_validTransmitters),
      F: 2,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });
    ocrConfigs[1] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 1,
      configDigest: _getBasicConfigDigest(1, s_validSigners, s_validTransmitters),
      F: 1,
      uniqueReports: true,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });
    ocrConfigs[2] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 2,
      configDigest: _getBasicConfigDigest(1, s_partialSigners, s_partialTransmitters),
      F: 1,
      uniqueReports: true,
      isSignatureVerificationEnabled: true,
      signers: s_partialSigners,
      transmitters: s_partialTransmitters
    });

    for (uint256 i; i < ocrConfigs.length; ++i) {
      vm.expectEmit();
      emit MultiOCR3Base.ConfigSet(
        ocrConfigs[i].ocrPluginType,
        ocrConfigs[i].configDigest,
        ocrConfigs[i].signers,
        ocrConfigs[i].transmitters,
        ocrConfigs[i].F
      );
    }
    s_multiOCR3.setOCR3Configs(ocrConfigs);

    for (uint256 i; i < ocrConfigs.length; ++i) {
      MultiOCR3Base.OCRConfig memory expectedConfig = MultiOCR3Base.OCRConfig({
        configInfo: MultiOCR3Base.ConfigInfo({
          configDigest: ocrConfigs[i].configDigest,
          F: ocrConfigs[i].F,
          n: uint8(ocrConfigs[i].signers.length),
          uniqueReports: ocrConfigs[i].uniqueReports,
          isSignatureVerificationEnabled: ocrConfigs[i].isSignatureVerificationEnabled
        }),
        signers: ocrConfigs[i].signers,
        transmitters: ocrConfigs[i].transmitters
      });
      _assertOCRConfigEquality(s_multiOCR3.latestConfigDetails(ocrConfigs[i].ocrPluginType), expectedConfig);
    }

    // pluginType 3 remains unconfigured
    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(3));
  }

  function test_Fuzz_SetConfig_Success(MultiOCR3Base.OCRConfigArgs memory ocrConfig, uint64 randomAddressOffset) public {
    // condition: cannot assume max oracle count
    vm.assume(ocrConfig.transmitters.length <= 31);

    // condition: F > 0
    ocrConfig.F = uint8(bound(ocrConfig.F, 1, 3));

    uint256 transmittersLength = ocrConfig.transmitters.length;

    // Force addresses to be unique (with a random offset for broader testing)
    for (uint160 i = 0; i < transmittersLength; ++i) {
      ocrConfig.transmitters[i] = vm.addr(PRIVATE0 + randomAddressOffset + i);
      // condition: non-zero oracle address
      vm.assume(ocrConfig.transmitters[i] != address(0));
    }

    if (ocrConfig.signers.length == 0) {
      ocrConfig.isSignatureVerificationEnabled = false;
    } else {
      ocrConfig.isSignatureVerificationEnabled = true;

      // condition: signers length must equal transmitters length
      if (ocrConfig.signers.length != transmittersLength) {
        ocrConfig.signers = new address[](transmittersLength);
      }

      // condition: number of signers > 3F
      vm.assume(ocrConfig.signers.length > 3 * ocrConfig.F);

      // Force addresses to be unique - continuing generation with an offset after the transmitter addresses
      for (uint160 i = 0; i < transmittersLength; ++i) {
        ocrConfig.signers[i] = vm.addr(PRIVATE0 + randomAddressOffset + i + transmittersLength);
        // condition: non-zero oracle address
        vm.assume(ocrConfig.signers[i] != address(0));
      }
    }

    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(ocrConfig.ocrPluginType));

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = ocrConfig;

    vm.expectEmit();
    emit MultiOCR3Base.ConfigSet(
      ocrConfig.ocrPluginType, ocrConfig.configDigest, ocrConfig.signers, ocrConfig.transmitters, ocrConfig.F
    );
    s_multiOCR3.setOCR3Configs(ocrConfigs);

    MultiOCR3Base.OCRConfig memory expectedConfig = MultiOCR3Base.OCRConfig({
      configInfo: MultiOCR3Base.ConfigInfo({
        configDigest: ocrConfig.configDigest,
        F: ocrConfig.F,
        n: uint8(ocrConfig.transmitters.length),
        uniqueReports: ocrConfig.uniqueReports,
        isSignatureVerificationEnabled: ocrConfig.isSignatureVerificationEnabled
      }),
      signers: ocrConfig.signers,
      transmitters: ocrConfig.transmitters
    });
    _assertOCRConfigEquality(s_multiOCR3.latestConfigDetails(ocrConfig.ocrPluginType), expectedConfig);
  }

  function test_UpdateConfigTransmittersWithoutSigners_Success() public {
    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(0));

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(1, s_emptySigners, s_validTransmitters),
      F: 1,
      uniqueReports: false,
      isSignatureVerificationEnabled: false,
      signers: s_emptySigners,
      transmitters: s_validTransmitters
    });
    s_multiOCR3.setOCR3Configs(ocrConfigs);

    address[] memory newTransmitters = s_partialSigners;

    ocrConfigs[0].F = 2;
    ocrConfigs[0].configDigest = _getBasicConfigDigest(2, s_emptySigners, newTransmitters);
    ocrConfigs[0].transmitters = newTransmitters;

    vm.expectEmit();
    emit MultiOCR3Base.ConfigSet(
      ocrConfigs[0].ocrPluginType,
      ocrConfigs[0].configDigest,
      ocrConfigs[0].signers,
      ocrConfigs[0].transmitters,
      ocrConfigs[0].F
    );

    s_multiOCR3.setOCR3Configs(ocrConfigs);

    MultiOCR3Base.OCRConfig memory expectedConfig = MultiOCR3Base.OCRConfig({
      configInfo: MultiOCR3Base.ConfigInfo({
        configDigest: ocrConfigs[0].configDigest,
        F: ocrConfigs[0].F,
        n: uint8(newTransmitters.length),
        uniqueReports: ocrConfigs[0].uniqueReports,
        isSignatureVerificationEnabled: ocrConfigs[0].isSignatureVerificationEnabled
      }),
      signers: s_emptySigners,
      transmitters: newTransmitters
    });
    _assertOCRConfigEquality(s_multiOCR3.latestConfigDetails(0), expectedConfig);

    // Verify oracle roles get correctly re-assigned
    for (uint256 i; i < newTransmitters.length; ++i) {
      MultiOCR3Base.Oracle memory transmitterOracle = s_multiOCR3.getOracle(0, newTransmitters[i]);
      assertEq(transmitterOracle.index, i);
      assertEq(uint8(transmitterOracle.role), uint8(MultiOCR3Base.Role.Transmitter));
    }

    // Verify old transmitters get correctly unset
    for (uint256 i = newTransmitters.length; i < s_validTransmitters.length; ++i) {
      MultiOCR3Base.Oracle memory transmitterOracle = s_multiOCR3.getOracle(0, s_validTransmitters[i]);
      assertEq(uint8(transmitterOracle.role), uint8(MultiOCR3Base.Role.Unset));
    }
  }

  function test_UpdateConfigSigners_Success() public {
    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(0));

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(2, s_validSigners, s_validTransmitters),
      F: 2,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });
    s_multiOCR3.setOCR3Configs(ocrConfigs);

    address[] memory newSigners = s_partialTransmitters;
    address[] memory newTransmitters = s_partialSigners;

    ocrConfigs[0].F = 1;
    ocrConfigs[0].configDigest = _getBasicConfigDigest(1, newSigners, newTransmitters);
    ocrConfigs[0].signers = newSigners;
    ocrConfigs[0].transmitters = newTransmitters;

    vm.expectEmit();
    emit MultiOCR3Base.ConfigSet(
      ocrConfigs[0].ocrPluginType,
      ocrConfigs[0].configDigest,
      ocrConfigs[0].signers,
      ocrConfigs[0].transmitters,
      ocrConfigs[0].F
    );

    s_multiOCR3.setOCR3Configs(ocrConfigs);

    MultiOCR3Base.OCRConfig memory expectedConfig = MultiOCR3Base.OCRConfig({
      configInfo: MultiOCR3Base.ConfigInfo({
        configDigest: ocrConfigs[0].configDigest,
        F: ocrConfigs[0].F,
        n: uint8(newSigners.length),
        uniqueReports: ocrConfigs[0].uniqueReports,
        isSignatureVerificationEnabled: ocrConfigs[0].isSignatureVerificationEnabled
      }),
      signers: newSigners,
      transmitters: newTransmitters
    });
    _assertOCRConfigEquality(s_multiOCR3.latestConfigDetails(0), expectedConfig);

    // Verify oracle roles get correctly re-assigned
    for (uint256 i; i < newSigners.length; ++i) {
      MultiOCR3Base.Oracle memory signerOracle = s_multiOCR3.getOracle(0, newSigners[i]);
      assertEq(signerOracle.index, i);
      assertEq(uint8(signerOracle.role), uint8(MultiOCR3Base.Role.Signer));

      MultiOCR3Base.Oracle memory transmitterOracle = s_multiOCR3.getOracle(0, newTransmitters[i]);
      assertEq(transmitterOracle.index, i);
      assertEq(uint8(transmitterOracle.role), uint8(MultiOCR3Base.Role.Transmitter));
    }

    // Verify old signers / transmitters get correctly unset
    for (uint256 i = newSigners.length; i < s_validSigners.length; ++i) {
      MultiOCR3Base.Oracle memory signerOracle = s_multiOCR3.getOracle(0, s_validSigners[i]);
      assertEq(uint8(signerOracle.role), uint8(MultiOCR3Base.Role.Unset));

      MultiOCR3Base.Oracle memory transmitterOracle = s_multiOCR3.getOracle(0, s_validTransmitters[i]);
      assertEq(uint8(transmitterOracle.role), uint8(MultiOCR3Base.Role.Unset));
    }
  }

  // Reverts

  function test_RepeatTransmitterAddress_Revert() public {
    address[] memory signers = s_validSigners;
    address[] memory transmitters = s_validTransmitters;
    transmitters[0] = signers[0];

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(1, signers, transmitters),
      F: 1,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: signers,
      transmitters: transmitters
    });

    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.InvalidConfig.selector, "repeated transmitter address"));
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_RepeatSignerAddress_Revert() public {
    address[] memory signers = s_validSigners;
    address[] memory transmitters = s_validTransmitters;
    signers[1] = signers[0];

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(1, signers, transmitters),
      F: 1,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: signers,
      transmitters: transmitters
    });

    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.InvalidConfig.selector, "repeated signer address"));
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_SignerCannotBeZeroAddress_Revert() public {
    uint8 F = 1;
    address[] memory signers = new address[](3 * F + 1);
    address[] memory transmitters = new address[](3 * F + 1);
    for (uint160 i = 0; i < 3 * F + 1; ++i) {
      signers[i] = address(i + 1);
      transmitters[i] = address(i + 1000);
    }

    signers[0] = address(0);

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(F, signers, transmitters),
      F: F,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: signers,
      transmitters: transmitters
    });

    vm.expectRevert(MultiOCR3Base.OracleCannotBeZeroAddress.selector);
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_TransmitterCannotBeZeroAddress_Revert() public {
    uint8 F = 1;
    address[] memory signers = new address[](3 * F + 1);
    address[] memory transmitters = new address[](3 * F + 1);
    for (uint160 i = 0; i < 3 * F + 1; ++i) {
      signers[i] = address(i + 1);
      transmitters[i] = address(i + 1000);
    }

    transmitters[0] = address(0);

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(F, signers, transmitters),
      F: F,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: signers,
      transmitters: transmitters
    });

    vm.expectRevert(MultiOCR3Base.OracleCannotBeZeroAddress.selector);
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_StaticConfigChange_Revert() public {
    uint8 F = 1;

    _assertOCRConfigUnconfigured(s_multiOCR3.latestConfigDetails(0));

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(F, s_validSigners, s_validTransmitters),
      F: F,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });

    s_multiOCR3.setOCR3Configs(ocrConfigs);

    // uniqueReports cannot change
    ocrConfigs[0].uniqueReports = true;
    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.StaticConfigCannotBeChanged.selector, 0));
    s_multiOCR3.setOCR3Configs(ocrConfigs);

    // signature verification cannot change
    ocrConfigs[0].uniqueReports = false;
    ocrConfigs[0].isSignatureVerificationEnabled = false;
    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.StaticConfigCannotBeChanged.selector, 0));
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_OracleOutOfRegister_Revert() public {
    address[] memory signers = new address[](10);
    address[] memory transmitters = new address[](0);

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(2, signers, transmitters),
      F: 1,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: signers,
      transmitters: transmitters
    });

    vm.expectRevert(
      abi.encodeWithSelector(MultiOCR3Base.InvalidConfig.selector, "oracle addresses out of registration")
    );
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_FTooHigh_Revert() public {
    address[] memory signers = new address[](0);
    address[] memory transmitters = new address[](0);

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(1, signers, transmitters),
      F: 1,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: signers,
      transmitters: transmitters
    });

    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.InvalidConfig.selector, "faulty-oracle F too high"));
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_FMustBePositive_Revert() public {
    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(0, s_validSigners, s_validTransmitters),
      F: 0,
      uniqueReports: false,
      isSignatureVerificationEnabled: true,
      signers: s_validSigners,
      transmitters: s_validTransmitters
    });

    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.InvalidConfig.selector, "F must be positive"));
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }

  function test_TooManyTransmitters_Revert() public {
    address[] memory signers = new address[](0);
    address[] memory transmitters = new address[](32);

    MultiOCR3Base.OCRConfigArgs[] memory ocrConfigs = new MultiOCR3Base.OCRConfigArgs[](1);
    ocrConfigs[0] = MultiOCR3Base.OCRConfigArgs({
      ocrPluginType: 0,
      configDigest: _getBasicConfigDigest(10, signers, transmitters),
      F: 10,
      uniqueReports: false,
      isSignatureVerificationEnabled: false,
      signers: signers,
      transmitters: transmitters
    });

    vm.expectRevert(abi.encodeWithSelector(MultiOCR3Base.InvalidConfig.selector, "too many transmitters"));
    s_multiOCR3.setOCR3Configs(ocrConfigs);
  }
}
