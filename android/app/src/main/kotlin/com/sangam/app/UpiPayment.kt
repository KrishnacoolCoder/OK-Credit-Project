package com.sangam.app

data class UpiPayment(
    val id: String = java.util.UUID.randomUUID().toString(),
    val amount: Double,
    val sender: String,
    val appSource: String,
    val timestamp: Long,
    val rawText: String
)
