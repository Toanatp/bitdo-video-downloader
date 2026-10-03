use tauri_plugin_updater::UpdaterExt;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_updater::Builder::new().build())
        .setup(|app| {
            let handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                let result = async {
                    let updater = handle
                        .updater_builder()
                        .target("windows-x86_64")
                        .version_comparator(|_, remote| remote.version.to_string() == "1.0.1")
                        .build()?;
                    let Some(update) = updater.check().await? else {
                        return Err("updater returned no update".into());
                    };
                    println!("FOUND_UPDATE version={} current={} url={}", update.version, update.current_version, update.download_url);
                    update
                        .download_and_install(
                            |chunk, total| println!("DOWNLOADED chunk={} total={:?}", chunk, total),
                            || println!("DOWNLOAD_FINISHED"),
                        )
                        .await?;
                    Ok::<(), Box<dyn std::error::Error + Send + Sync>>(())
                }
                .await;

                if let Err(error) = result {
                    eprintln!("UPDATER_PROBE_ERROR: {error}");
                    handle.exit(1);
                }
            });
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("failed to run updater probe");
}
