require 'xcodeproj'
project = Xcodeproj::Project.open("Parse/Parse.xcodeproj")
public_headers = [
"PFEventuallyPin.h",
"PFInstallation.h",
"PFPin.h",
"PFProduct.h",
"PFSession.h",
"PFUser.h"]
project.targets.each do |target|
    if target.name == "Parse-iOS"
        group = project.main_group
        file_ref = group.new_reference("Parse/ParseCore.h")
        header = target.headers_build_phase.add_file_reference(file_ref)
        header.settings = { 'ATTRIBUTES' => ['Public'] }
        for i in 0..target.headers_build_phase.files.length - 1
            if public_headers.include? i
                build_file = target.headers_build_phase.files[i]
                build_file.settings = { 'ATTRIBUTES' => ['Public']}
            end
        end
#        framework_ref = group.new_reference("Bolts.xcframework")
#        framework = target.frameworks_build_phase.add_file_reference(framework_ref)
#
#        embed_frameworks_build_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
#        embed_frameworks_build_phase.name = 'Embed Frameworks'
#        embeded_framework = embed_frameworks_build_phase.add_file_reference(framework_ref)
#        embeded_framework.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy'] }
#        embed_frameworks_build_phase.symbol_dst_subfolder_spec = :frameworks
#        target.build_phases << embed_frameworks_build_phase
#
#        target.dependencies.each { |e| e.remove_from_project }
        project.save
    end
end
