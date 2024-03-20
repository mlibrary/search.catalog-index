S.register(:project_root) do
  File.absolute_path(File.join(__dir__, "../../"))
end

S.register(:scratch_dir) { File.join(S.project_root, "scratch") }
