CXX = 'clang++'
LD  = CXX
PEG = 'greg'

BUILD_DIR = 'Build'

PARSER_OUTPATH = "#{BUILD_DIR}/parse.mm"

PEGFLAGS = [
    "-o #{PARSER_OUTPATH}",
    #"-v"
].join(' ')

CXXFLAGS = [
    '-DDEBUG',
    '-std=gnu++98',
    '-mmacosx-version-min=10.7',
    '-I`pwd`/Source',
    '-I/usr/include/libxml2',
    '-Wno-deprecated-writable-strings', # BridgeSupport uses this in a few places
    '`llvm-config --cflags`',
    '-O0',
    '-g',
    '-ObjC++',
    #'--analyze'
].join(' ')


LDFLAGS = [
    '-lstdc++',
    '`llvm-config --libs core jit nativecodegen bitwriter ipo instrumentation`',
    '`llvm-config --ldflags`',
    '-framework Foundation',
    '-framework AppKit',
    '-all_load',
    '-lxml2 -lffi',
].join(' ')

LIBS = ['-framework Foundation', '-framework GLUT'].join(' ')

PATHMAP = "build/%n.o"

STUB_OUTPATH   = 'Build/block_stubs.mm'
STUB_SCRIPT    = 'Source/Tranquil/gen_stubs.rb'
MSGSEND_SOURCE = 'Source/Tranquil/Runtime/msgsend.s'
MSGSEND_OUT    = "Build/msgsend.o"
OBJC_SOURCES   = FileList['Source/Tranquil/**/*.m*'].add('Source/Tranquil/**/*.c').add(PARSER_OUTPATH).add(STUB_OUTPATH)
O_FILES        = OBJC_SOURCES.pathmap(PATHMAP)
O_FILES << MSGSEND_OUT
PEG_SOURCE     = FileList['Source/Tranquil/*.leg'].first


def compile(file, flags=CXXFLAGS, cc=CXX)
    sh "#{cc} #{file[:in].join(' ')} #{flags} -c -o #{file[:out]}"
end

file PARSER_OUTPATH => PEG_SOURCE do |f|
    sh "#{PEG} #{PEGFLAGS} #{PEG_SOURCE}"
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

file :tranquil => O_FILES do |t|
    sh "#{LD} #{LDFLAGS} #{LIBS} #{O_FILES} -o #{BUILD_DIR}/#{t.name}"
end

task :default => [:build_dir, :tranquil]

task :run => [:default] do
    sh "#{BUILD_DIR}/tranquil"
end

task :gdb => [:default] do
    sh "gdb #{BUILD_DIR}/tranquil"
end

task :lldb => [:default] do
    sh "lldb #{BUILD_DIR}/tranquil"
end
