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
	'-lxml2'
].join(' ')

LIBS = ['-framework Foundation'].join(' ')

PATHMAP = "build/%n.o"

OBJC_SOURCES = FileList['Source/*.m*'].add('Source/*/*.m*').add('Source/*/*.c').add(PARSER_OUTPATH)
O_FILES = OBJC_SOURCES.pathmap(PATHMAP)
PEG_SOURCE = FileList['Source/*.leg'].first

def compile(file, flags=CXXFLAGS, cc=CXX)
	sh "#{cc} #{file[:in].join(' ')} #{flags} -c -o #{file[:out]}"
end

file PARSER_OUTPATH => PEG_SOURCE do |f|
	sh "#{PEG} #{PEGFLAGS} #{PEG_SOURCE}"
end

OBJC_SOURCES.each { |src|
	file src.pathmap(PATHMAP) => src do |f|
		compile :in => f.prerequisites, :out => f.name
	end
}

file :tranquil => O_FILES do |t|
	sh "#{LD} #{LDFLAGS} #{LIBS} #{O_FILES} -o #{BUILD_DIR}/#{t.name}"
end

task :default => [:tranquil]

task :run => [:default] do
	sh "#{BUILD_DIR}/tranquil"
end

task :gdb => [:default] do
	sh "gdb #{BUILD_DIR}/tranquil"
end

task :lldb => [:default] do
	sh "lldb #{BUILD_DIR}/tranquil"
end
