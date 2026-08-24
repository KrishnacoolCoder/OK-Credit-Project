package com.sangam.app

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

object UpiPaymentBroadcaster {
    private val _flow = MutableSharedFlow<UpiPayment>(extraBufferCapacity = 64)
    val flow = _flow.asSharedFlow()

    fun emit(payment: UpiPayment) {
        _flow.tryEmit(payment)
    }
}
