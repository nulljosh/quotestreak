package com.nulljosh.quotestreak

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class Quote(
    val quote: String,
    val year: Int,
    val options: List<String>,
    val genre: String,
    val answer: String,
    val type: String,
    val art: String = "",
)

// Reads the same static quotes.json the web app ships. quotestreak has no
// backend, so there is nothing else to port.
class QuotestreakClient(private val baseUrl: String = "https://quotestreak.heyitsmejosh.com") {
    private val http = HttpClient {
        install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
    }

    suspend fun quotes(): List<Quote> = http.get("$baseUrl/quotes.json").body()
}
