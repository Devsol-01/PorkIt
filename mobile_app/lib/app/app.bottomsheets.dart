// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedBottomsheetGenerator
// **************************************************************************

import 'package:stacked_services/stacked_services.dart';

import 'app.locator.dart';
import '../ui/bottom_sheets/bank_transfer/bank_transfer_sheet.dart';
import '../ui/bottom_sheets/card_deposit/card_deposit_sheet.dart';
import '../ui/bottom_sheets/chain_selection/chain_selection_sheet.dart';
import '../ui/bottom_sheets/crypto_deposit/crypto_deposit_sheet.dart';
import '../ui/bottom_sheets/crypto_method_selection/crypto_method_selection_sheet.dart';
import '../ui/bottom_sheets/crypto_send/crypto_send_sheet.dart';
import '../ui/bottom_sheets/deposit/deposit_sheet.dart';
import '../ui/bottom_sheets/fiat_method_selection/fiat_method_selection_sheet.dart';
import '../ui/bottom_sheets/fiat_send_selection/fiat_send_selection_sheet.dart';
import '../ui/bottom_sheets/group_save_selection/group_save_selection_sheet.dart';
import '../ui/bottom_sheets/language_selection/language_selection_sheet.dart';
import '../ui/bottom_sheets/ngn_send/ngn_send_sheet.dart';
import '../ui/bottom_sheets/send/send_sheet.dart';
import '../ui/bottom_sheets/virtual_account/virtual_account_sheet.dart';
import '../ui/bottom_sheets/withdraw/withdraw_sheet.dart';

enum BottomSheetType {
  cryptoDeposit,
  deposit,
  withdraw,
  groupSaveSelection,
  send,
  cryptoSend,
  fiatSendSelection,
  ngnSend,
  cryptoMethodSelection,
  chainSelection,
  fiatMethodSelection,
  cardDeposit,
  bankTransfer,
  virtualAccount,
  languageSelection,
}

void setupBottomSheetUi() {
  final bottomsheetService = locator<BottomSheetService>();

  final Map<BottomSheetType, SheetBuilder> builders = {
    BottomSheetType.cryptoDeposit: (context, request, completer) =>
        CryptoDepositSheet(request: request, completer: completer),
    BottomSheetType.deposit: (context, request, completer) =>
        DepositSheet(request: request, completer: completer),
    BottomSheetType.withdraw: (context, request, completer) =>
        WithdrawSheet(request: request, completer: completer),
    BottomSheetType.groupSaveSelection: (context, request, completer) =>
        GroupSaveSelectionSheet(request: request, completer: completer),
    BottomSheetType.send: (context, request, completer) =>
        SendSheet(request: request, completer: completer),
    BottomSheetType.cryptoSend: (context, request, completer) =>
        CryptoSendSheet(request: request, completer: completer),
    BottomSheetType.fiatSendSelection: (context, request, completer) =>
        FiatSendSelectionSheet(request: request, completer: completer),
    BottomSheetType.ngnSend: (context, request, completer) =>
        NgnSendSheet(request: request, completer: completer),
    BottomSheetType.cryptoMethodSelection: (context, request, completer) =>
        CryptoMethodSelectionSheet(request: request, completer: completer),
    BottomSheetType.chainSelection: (context, request, completer) =>
        ChainSelectionSheet(request: request, completer: completer),
    BottomSheetType.fiatMethodSelection: (context, request, completer) =>
        FiatMethodSelectionSheet(request: request, completer: completer),
    BottomSheetType.cardDeposit: (context, request, completer) =>
        CardDepositSheet(request: request, completer: completer),
    BottomSheetType.bankTransfer: (context, request, completer) =>
        BankTransferSheet(request: request, completer: completer),
    BottomSheetType.virtualAccount: (context, request, completer) =>
        VirtualAccountSheet(request: request, completer: completer),
    BottomSheetType.languageSelection: (context, request, completer) =>
        LanguageSelectionSheet(context, request, completer),
  };

  bottomsheetService.setCustomSheetBuilders(builders);
}
