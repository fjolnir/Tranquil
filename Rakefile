CXX = '/usr/local/llvm/bin/clang++'
LD  = CXX
PEG = '/usr/local/greg/bin/greg'

BUILD_DIR = 'Build'

PARSER_OUTPATH = "#{BUILD_DIR}/parse.m"

PEGFLAGS = [
    "-o #{PARSER_OUTPATH}",
    #"-v"
].join(' ')


CXXFLAGS = {
    :release => [
        '-std=gnu++98',
        '-mmacosx-version-min=10.7',
        '-I`pwd`/Source',
        '-I`pwd`/Build',
        '-I/usr/include/libxml2',
        '-Wno-deprecated-writable-strings', # BridgeSupport uses this in a few places
        '`/usr/local/llvm/bin/llvm-config --cflags`',
        '-O3',
        '-ObjC++',
    ].join(' '),
    :development => [
        '-DDEBUG',
        '-std=gnu++98',
        '-mmacosx-version-min=10.7',
        '-I/usr/local/clang/include',
        '-I`pwd`/Source',
        '-I`pwd`/Build',
        '-I/usr/include/libxml2',
        '-Wno-deprecated-writable-strings', # BridgeSupport uses this in a few places
        '`/usr/local/llvm/bin/llvm-config --cflags`',
        '-O0',
        '-g',
        '-ObjC++',
        #'--analyze'
    ].join(' ')
}

LDFLAGS = [
    '-lstdc++',
    '`/usr/local/llvm/bin/llvm-config --libs core jit nativecodegen bitwriter ipo instrumentation`',
    '`/usr/local/llvm/bin/llvm-config --ldflags`',
    '-lclang',
    '-rpath /usr/local/llvm/lib',
    '-framework Foundation',
    '-framework AppKit',
    '-all_load',
    '-lxml2 -lffi',
].join(' ')

TOOL_LDFLAGS = [
    '-framework Foundation',
    '-framework AppKit',
    '-all_load',
].join(' ')


LIBS = ['-framework Foundation', '-framework GLUT'].join(' ')

PATHMAP = 'build/%n.o'

STUB_OUTPATH   = 'Build/block_stubs.mm'
STUB_SCRIPT    = 'Source/Tranquil/gen_stubs.rb'
MSGSEND_SOURCE = 'Source/Tranquil/Runtime/msgsend.s'
MSGSEND_OUT    = 'Build/msgsend.o'
OBJC_SOURCES   = FileList['Source/Tranquil/**/*.m*'].add('Source/Tranquil/**/*.c*').add(STUB_OUTPATH)
O_FILES        = OBJC_SOURCES.pathmap(PATHMAP)
O_FILES << MSGSEND_OUT
PEG_SOURCE     = FileList['Source/Tranquil/*.leg'].first

ARC_FILES = ['Source/Tranquil/Runtime/TQWeak.m']

MAIN_SOURCE = 'Source/main.m'

@buildMode = :development

def compile(file, flags=CXXFLAGS, cc=CXX)
    cmd = "#{cc} #{file[:in].join(' ')} #{flags[@buildMode]} -c -o #{file[:out]}"
    cmd << " -fobjc-arc" if ARC_FILES.member? file[:in].first
    sh cmd
end

file PARSER_OUTPATH => PEG_SOURCE do |f|
    sh "#{PEG} #{PEGFLAGS} #{PEG_SOURCE}"
    compile :in => ['Source/Tranquil/TQProgram.mm'], :out => 'Build/TQProgram.o'
end

file STUB_OUTPATH => STUB_SCRIPT do |f|
    sh "ruby #{STUB_SCRIPT} > #{STUB_OUTPATH}"
end

file MSGSEND_OUT => MSGSEND_SOURCE do |f|
    sh "#{CXX} #{MSGSEND_SOURCE} -c -o #{MSGSEND_OUT}"
end


OBJC_SOURCES.each { |src|
    file src.pathmap(PATHMAP) => src do |f|
        compile :in => f.prerequisites, :out => f.name
    end
}

file :build_dir do
    sh "mkdir -p #{File.dirname(__FILE__)}/Build"
end

file :libtranquil => [PARSER_OUTPATH] + O_FILES do |t|
    sh "#{LD} #{LDFLAGS} #{LIBS} #{O_FILES} -dynamiclib -o #{BUILD_DIR}/libtranquil.dylib"
end

file :tranquil => [:libtranquil] do |t|
    oFile = "#{BUILD_DIR}/main.o"
    cmd = "#{CXX} #{MAIN_SOURCE} #{CXXFLAGS[@buildMode]} -c -o  #{BUILD_DIR}/main.o"
    sh "#{LD} #{TOOL_LDFLAGS} #{LIBS} #{oFile} -LBuild -ltranquil -o #{BUILD_DIR}/tranquil"
end
file :setReleaseOpts do
    p "Release build"
    @buildMode = :release
end

task :run => [:default] do
    sh "#{BUILD_DIR}/tranquil"
end

task :gdb => [:default] do
    sh "gdb #{BUILD_DIR}/tranquil"
end

task :lldb => [:default] do
    sh "lldb #{BUILD_DIR}/tranquil"
end

task :clean do
    sh "rm Build/*"
end

task :default => [:build_dir, :tranquil]
task :release => [:clean, :setReleaseOpts, :build_dir, :tranquil]
