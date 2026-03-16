trigger QrBillUpdateEventTrigger on QR_Bill_Update_Event__e (after insert) {

    if(Trigger.isAfter){
        system.debug('$$$ QrBillUpdateEventTrigger');
        if (Trigger.isInsert) {
            QRBillPARXService.updateQRBill(Trigger.new);
        }
    }

}