S.register(:project_root) do
  File.absolute_path(File.join(__dir__, "../../"))
end

S.register(:scratch_dir) { File.join(S.project_root, "scratch") }

S.register(:translation_map_dir) do
  if S.app_env == "test"
    File.join(S.project_root, "spec", "fixtures", "translation_maps")
  else
    File.join(S.project_root, "lib", "translation_maps")
  end
end
