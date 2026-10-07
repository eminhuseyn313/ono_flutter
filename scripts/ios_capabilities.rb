#!/usr/bin/env ruby
# Applies opt-in iOS capabilities to Runner.xcodeproj. Idempotent.
#   ruby scripts/ios_capabilities.rb health widget
#
# health: HealthKit entitlement on the app (Apple Health).
# widget: the ONOWidget WidgetKit extension (ios/ONOWidget) plus an app group
#         shared by the app and the widget.
#
# Opt-in because your Apple team must support them; use
# `bash scripts/capabilities.sh` rather than calling this directly — it
# remembers the choice and re-applies it after every update.
require 'xcodeproj'

GROUP_ID = 'group.com.eminhuseynzade.ono'.freeze
IOS = File.expand_path('../ios', __dir__)
wanted = ARGV.map(&:downcase)
abort('usage: ios_capabilities.rb [health] [widget]') if (wanted - %w[health widget]).any?
project = Xcodeproj::Project.open(File.join(IOS, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' } or abort('Runner target not found')

# Merge [entries] into the app's entitlements file and point the target at it.
def merge_runner_entitlements(project, runner)
  rel = runner.build_configurations.map { |c| c.build_settings['CODE_SIGN_ENTITLEMENTS'] }
              .compact.first || 'Runner/Runner.entitlements'
  path = File.join(IOS, rel)
  ent = File.exist?(path) ? Xcodeproj::Plist.read_from_path(path) : {}
  yield ent
  Xcodeproj::Plist.write_to_path(ent, path)
  runner.build_configurations.each { |c| c.build_settings['CODE_SIGN_ENTITLEMENTS'] = rel }
  group = project.main_group.children.find { |g| g.display_name == 'Runner' }
  if group && group.files.none? { |f| f.path.to_s.end_with?(File.basename(rel)) }
    group.new_reference(File.basename(rel))
  end
end

def add_widget(project, runner)
  base = runner.build_configurations.find { |c| c.name == 'Release' }.build_settings
  team = base['DEVELOPMENT_TEAM']
  app_id = base['PRODUCT_BUNDLE_IDENTIFIER'] or abort('Runner has no bundle id')

  # Files
  group = project.main_group.new_group('ONOWidget', 'ONOWidget')
  swift = group.new_reference('ONOWidget.swift')
  group.new_reference('Info.plist')
  group.new_reference('ONOWidget.entitlements')
  xcconfig = group.new_reference('Widget.xcconfig')

  # Target
  widget = project.new_target(:app_extension, 'ONOWidget', :ios, '17.0', nil, :swift)
  widget.add_file_references([swift])
  widget.add_system_frameworks(%w[WidgetKit SwiftUI])
  # Flutter builds Debug, Release and Profile; give the widget all three.
  unless widget.build_configurations.any? { |c| c.name == 'Profile' }
    widget.add_build_configuration('Profile', :release)
  end
  widget.build_configurations.each do |c|
    c.base_configuration_reference = xcconfig
    s = c.build_settings
    s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{app_id}.widget"
    s['PRODUCT_NAME'] = '$(TARGET_NAME)'
    s['INFOPLIST_FILE'] = 'ONOWidget/Info.plist'
    s['GENERATE_INFOPLIST_FILE'] = 'NO'
    s['CODE_SIGN_ENTITLEMENTS'] = 'ONOWidget/ONOWidget.entitlements'
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['DEVELOPMENT_TEAM'] = team if team
    s['SWIFT_VERSION'] = '5.0'
    s['TARGETED_DEVICE_FAMILY'] = '1'
    s['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    s['SKIP_INSTALL'] = 'YES'
    s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
    s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                    '@executable_path/../../Frameworks']
  end

  # Embed in the app. The embed phase must run before Flutter's "Thin Binary"
  # script, or Xcode reports a dependency cycle.
  runner.add_dependency(widget)
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
  embed.add_file_reference(widget.product_reference, true)
       .settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  phases = runner.build_phases
  phases.delete(embed)
  thin = phases.index do |p|
    p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
      p.display_name.to_s.include?('Thin Binary')
  end
  phases.insert(thin || phases.length, embed)

  # App group on the app too.
  merge_runner_entitlements(project, runner) do |ent|
    groups = Array(ent['com.apple.security.application-groups'])
    groups << GROUP_ID unless groups.include?(GROUP_ID)
    ent['com.apple.security.application-groups'] = groups
  end
end

if wanted.include?('health')
  merge_runner_entitlements(project, runner) do |ent|
    ent['com.apple.developer.healthkit'] = true
    ent['com.apple.developer.healthkit.access'] ||= []
  end
  puts 'HealthKit: on.'
end

if wanted.include?('widget')
  if project.targets.any? { |t| t.name == 'ONOWidget' }
    puts 'Widget: already in the project.'
  else
    add_widget(project, runner)
    puts 'Widget: added, with the shared app group.'
  end
end

project.save
