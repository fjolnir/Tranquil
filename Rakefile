CC  = '/usr/local/llvm/bin/clang'
CXX = '/usr/local/llvm/bin/clang++'
LD  = CC
PEG = '/usr/local/greg/bin/greg'

BUILD_DIR = 'Build'

PARSER_OUTPATH = "#{BUILD_DIR}/parse.m"

PEGFLAGS = [
    "-o #{PARSER_OUTPATH}",
    #"-v"
].join(' ')


CXXFLAGS = {
    :release => [
        '-mmacosx-version-min=10.7',
        '-I`pwd`/Source',
        '-I`pwd`/Build',
        '-I/usr/include/libxml2',
        '-Wno-deprecated-writable-strings', # BridgeSupport uses this in a few places
        '`/usr/local/llvm/bin/llvm-config --cflags`',
        '-O3',
    ].join(' '),
    :development => [
        '-DDEBUG',
        '-mmacosx-version-min=10.7',
        '-I/usr/local/clang/include',
        '-I`pwd`/Source',
        '-I`pwd`/Build',
        '-I/usr/include/libxml2',
        '-Wno-deprecated-writable-strings', # BridgeSupport uses this in a few places
        '`/usr/local/llvm/bin/llvm-config --cflags`',
        '-O0',
        '-g',
        #'--analyze'
    ].join(' ')
}

LDFLAGS = [
    '-L`pwd`/Build',
    '-framework Foundation',
    '-framework AppKit',
    '-all_load',
    '-lffi',
].join(' ')

CODEGEN_LDFLAGS = LDFLAGS + ' ' + [
    '-lstdc++',
    '`/usr/local/llvm/bin/llvm-config --libs core jit nativecodegen bitwriter ipo instrumentation`',
    '`/usr/local/llvm/bin/llvm-config --ldflags`',
    '-lclang',
    '-rpath /usr/local/llvm/lib'
].join(' ')

TOOL_LDFLAGS = [
    '-lstdc++',
    '-lffi',
    '-framework Foundation',
    '-framework AppKit',
    '-all_load',
].join(' ')


LIBS = ['-framework Foundation', '-framework GLUT'].join(' ')

PATHMAP = 'build/%n.o'

STUB_OUTPATH    = 'Build/block_stubs.m'
STUB_SCRIPT     = 'Source/Tranquil/gen_stubs.rb'
MSGSEND_SOURCE  = 'Source/Tranquil/Runtime/msgsend.s'
MSGSEND_OUT     = 'Build/msgsend.o'
RUNTIME_SOURCES = FileList['Source/Tranquil/BridgeSupport/*.m*'].add('Source/Tranquil/Dispatch/*.m*').add('Source/Tranquil/Runtime/*.m*').add('Source/Tranquil/Shared/*.m*').add(STUB_OUTPATH)
RUNTIME_O_FILES = RUNTIME_SOURCES.pathmap(PATHMAP)
RUNTIME_O_FILES << MSGSEND_OUT

CODEGEN_SOURCES = FileList['Source/Tranquil/CodeGen/**/*.m*']
CODEGEN_O_FILES = CODEGEN_SOURCES.pathmap(PATHMAP)

PEG_SOURCE      = FileList['Source/Tranquil/*.leg'].first

ARC_FILES = ['Source/Tranquil/Runtime/TQWeak.m']

MAIN_SOURCE  = 'Source/main.m'
MAIN_OUTPATH = 'Build/main.o'


@buildMode = :development

def compile(file, flags=CXXFLAGS, cc=CXX)
    cmd = "#{cc} #{file[:in].join(' ')} #{flags[@buildMode]} -c -o #{file[:out]}"
    cmd << " -fobjc-arc" if ARC_FILES.member? file[:in].first
    cmd << " -ObjC++"     if cc == CXX
    cmd << " -ObjC"       if cc == CC
    sh cmd
end

file PARSER_OUTPATH => PEG_SOURCE do |f|
    sh "#{PEG} #{PEGFLAGS} #{PEG_SOURCE}"
    compile :in => ['Source/Tranquil/CodeGen/TQProgram.mm'], :out => 'Build/TQProgram.o'
end

file STUB_OUTPATH => STUB_SCRIPT do |f|
    sh "ruby #{STUB_SCRIPT} > #{STUB_OUTPATH}"
end

file MSGSEND_OUT => MSGSEND_SOURCE do |f|
    sh "#{CXX} #{MSGSEND_SOURCE} -c -o #{MSGSEND_OUT}"
end


RUNTIME_SOURCES.each { |src|
    file src.pathmap(PATHMAP) => src do |f|
        compile({:in => f.prerequisites, :out => f.name}, CXXFLAGS, CC)
    end
}
CODEGEN_SOURCES.each { |src|
    file src.pathmap(PATHMAP) => src do |f|
        compile :in => f.prerequisites, :out => f.name
    end
}


file :build_dir do
    sh "mkdir -p #{File.dirname(__FILE__)}/Build"
end

file :libtranquil => RUNTIME_O_FILES do |t|
    #sh "#{LD} #{LDFLAGS} #{LIBS} #{RUNTIME_O_FILES} -static -o #{BUILD_DIR}/libtranquil.a"
    sh "ar rcs #{BUILD_DIR}/libtranquil.a #{RUNTIME_O_FILES}"
end

file :libtranquil_codegen => [PARSER_OUTPATH] + CODEGEN_O_FILES do |t|
    sh "#{LD} #{CODEGEN_LDFLAGS} #{LIBS} #{CODEGEN_O_FILES} -ltranquil -dynamiclib -o #{BUILD_DIR}/libtranquil_codegen.dylib"
end


file MAIN_OUTPATH => MAIN_SOURCE do |t|
    sh "#{CXX} #{MAIN_SOURCE} #{CXXFLAGS[@buildMode]} -ObjC++ -c -o #{MAIN_OUTPATH}"
end

file :tranquil => [:libtranquil, :libtranquil_codegen, MAIN_OUTPATH] do |t|
    sh "#{LD} #{TOOL_LDFLAGS} #{LIBS} #{MAIN_OUTPATH} -LBuild -ltranquil_codegen -o #{BUILD_DIR}/tranquil"
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
