package com.nulljosh.quotestreak

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun QuotestreakTheme(content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = lightColorScheme(), content = content)

@Composable
fun AppScreen(client: QuotestreakClient = QuotestreakClient()) {
    var quotes by remember { mutableStateOf<List<Quote>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    var index by remember { mutableStateOf(0) }
    var streak by remember { mutableStateOf(0) }
    var feedback by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        runCatching { quotes = client.quotes().shuffled() }
            .onFailure { error = it.message ?: "failed to load" }
        loading = false
    }

    fun next() {
        feedback = null
        index = (index + 1) % quotes.size
    }

    fun guess(option: String) {
        val current = quotes.getOrNull(index) ?: return
        if (option == current.answer) {
            streak++
            feedback = "Correct!"
        } else {
            streak = 0
            feedback = "It was ${current.answer}"
        }
    }

    Surface {
        Column(Modifier.fillMaxSize().padding(24.dp)) {
            Text("Quotestreak", style = MaterialTheme.typography.headlineMedium)
            Text("Streak: $streak", modifier = Modifier.padding(top = 4.dp))
            when {
                loading -> CircularProgressIndicator(Modifier.padding(top = 24.dp))
                error != null -> Text(error!!, modifier = Modifier.padding(top = 16.dp))
                quotes.isEmpty() -> Text("No quotes loaded")
                else -> {
                    val q = quotes[index]
                    Text(
                        "\"${q.quote}\" (${q.year})",
                        style = MaterialTheme.typography.titleLarge,
                        modifier = Modifier.padding(top = 24.dp, bottom = 16.dp),
                    )
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        q.options.forEach { opt ->
                            Button(onClick = { guess(opt) }, modifier = Modifier.fillMaxWidth()) {
                                Text(opt)
                            }
                        }
                    }
                    feedback?.let {
                        Text(it, modifier = Modifier.padding(top = 16.dp))
                        Button(onClick = { next() }, modifier = Modifier.padding(top = 8.dp)) {
                            Text("Next")
                        }
                    }
                }
            }
        }
    }
}
