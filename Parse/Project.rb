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
        project.save
    end
end
