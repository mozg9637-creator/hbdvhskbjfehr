use std::fs;
use std::process::Command;
use tokio::net::UnixListener;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

const SOCKET_PATH: &str = "/dev/socket/auragitd";
const SYSTEM_MOUNT_POINT: &str = "/system";

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("AuraGit OS: Инициализация Демона Состояний Ядра...");

    // Удаляем старый сокет, если он остался после перезагрузки
    let _ = fs::remove_file(SOCKET_PATH);

    // Открываем UNIX-сокет для общения с UI настроек OneUI
    let listener = UnixListener::bind(SOCKET_PATH)?;
    // Даем права системным приложениям писать в наш сокет
    Command::new("chmod").args(["0660", SOCKET_PATH]).status()?;
    Command::new("chown").args(["system:system", SOCKET_PATH]).status()?;

    loop {
        let (mut socket, _) = listener.accept().await?;
        
        tokio::spawn(async move {
            let mut buffer = [0; 1024];
            match socket.read(&mut buffer).await {
                Ok(bytes_read) if bytes_read > 0 => {
                    let command = String::from_utf8_lossy(&buffer[..bytes_read]).trim().to_string();
                    println!("AuraGit OS: Получена команда: {}", command);

                    let response = match command.as_str() {
                        "COMMIT_STATE" => commit_system_state(),
                        "ROLLBACK_STATE" => rollback_system_state(),
                        "GET_STATUS" => Ok("STATUS: SYNCED".to_string()),
                        _ => Err("Неизвестная команда".to_string()),
                    };

                    let reply = match response {
                        Ok(msg) => format!("SUCCESS: {}", msg),
                        Err(err) => format!("ERROR: {}", err),
                    };

                    let _ = socket.write_all(reply.as_bytes()).await;
                }
                _ => {}
            }
        });
    }
}

// Функция сохранения текущего состояния системы (Аналог git commit)
fn commit_system_state() -> Result<String, String> {
    // В реальной AuraGit OS здесь происходит создание read-only снапшота файловой системы
    let status = Command::new("git")
        .args(["--git-dir=/data/.auragit", "--work-tree=/", "add", "-A"])
        .status();

    match status {
        Ok(_) => {
            Command::new("git")
                .args(["--git-dir=/data/.auragit", "commit", "-m", "System Auto-Commit via AuraGit UI"])
                .status()
                .map_err(|e| e.to_string())?;
            Ok("Точка восстановления создана успешно!".to_string())
        }
        Err(e) => Err(format!("Ошибка инициализации коммита: {}", e)),
    }
}

// Функция отката системы к предыдущему стабильному коммиту
fn rollback_system_state() -> Result<String, String> {
    let status = Command::new("git")
        .args(["--git-dir=/data/.auragit", "--work-tree=/", "reset", "--hard", "HEAD~1"])
        .status();

    match status {
        Ok(_) => Ok("Система успешно откачена. Требуется перезагрузка!".to_string()),
        Err(e) => Err(format!("Критический сбой отката: {}", e)),
    }
}