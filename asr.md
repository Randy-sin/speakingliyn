本文介绍Fun-ASR实时语音识别Python SDK的参数和接口细节。

用户指南：关于模型介绍和选型建议请参见实时语音识别。

前提条件
已开通服务并获取API Key。请配置API Key到环境变量，而非硬编码在代码中，防范因代码泄露导致的安全风险。

说明
当您需要为第三方应用或用户提供临时访问权限，或者希望严格控制敏感数据访问、删除等高风险操作时，建议使用临时鉴权Token。

与长期有效的 API Key 相比，临时鉴权 Token 具备时效性短（60秒）、安全性高的特点，适用于临时调用场景，能有效降低API Key泄露的风险。

使用方式：在代码中，将原本用于鉴权的 API Key 替换为获取到的临时鉴权 Token 即可。

安装最新版DashScope SDK。

快速开始
Recognition类提供了同步调用和流式调用等接口。请根据实际需求选择合适的调用方式：

同步调用：针对本地文件进行识别，并一次性返回完整的处理结果。适合处理录制好的音频。

流式调用：可直接对音频流进行识别，并实时输出结果。音频流可以来自外部设备（如麦克风）或从本地文件读取。适合需要即时反馈的场景。

同步调用
提交单个语音实时转写任务，通过传入本地文件的方式同步阻塞地拿到转写结果。

实例化Recognition类绑定请求参数，调用call进行识别/翻译并最终获取识别结果（RecognitionResult）。

点击查看完整示例

流式调用
提交单个语音实时转写任务，通过实现回调接口的方式流式输出实时识别结果。

启动流式语音识别

实例化Recognition类绑定请求参数和回调接口（RecognitionCallback），调用start方法启动流式语音识别。

流式传输

循环调用Recognition类的send_audio_frame方法，将从本地文件或设备（如麦克风）读取的二进制音频流分段发送至服务端。

在发送音频数据的过程中，服务端会通过回调接口（RecognitionCallback）的on_event方法，将识别结果实时返回给客户端。

建议每次发送的音频时长约为100毫秒，数据大小保持在1KB至16KB之间。

结束处理

调用Recognition类的stop方法结束语音识别。

该方法会阻塞当前线程，直到回调接口（RecognitionCallback）的on_complete或者on_error回调触发后才会释放线程阻塞。

点击查看完整示例

请求参数
请求参数通过Recognition类的构造方法（_init_）进行设置。






参数

类型

默认值

是否必须

说明

model

str

-

是

用于实时语音识别的模型

sample_rate

int

-

是

设置待识别音频采样率（单位Hz）。

fun-asr-realtime支持16000Hz采样。

format

str

-

是

设置待识别音频格式。

支持的音频格式：pcm、wav、mp3、opus、speex、aac、amr。

重要
opus/speex：必须使用Ogg封装；

wav：必须为PCM编码；

amr：仅支持AMR-NB类型。

vocabulary_id

str

-

否

设置热词ID，若未设置则不生效。v1系列模型设置热词ID时使用该字段。

在本次语音识别中，将应用与该热词ID对应的热词信息。具体使用方法请参见Paraformer语音识别热词定制与管理。

phrase_id

str

-

否

设置热词ID，若未设置则不生效。v1系列模型设置热词ID时使用该字段。

在本次语音识别中，将应用与该热词ID对应的热词信息。具体使用方法请参见Paraformer语音识别热词定制与管理。

semantic_punctuation_enabled

bool

False

否

设置是否开启语义断句，默认关闭。

true：开启语义断句，关闭VAD（Voice Activity Detection，语音活动检测）断句。

false（默认）：开启VAD（Voice Activity Detection，语音活动检测）断句，关闭语义断句。

语义断句准确性更高，适合会议转写场景；VAD（Voice Activity Detection，语音活动检测）断句延迟较低，适合交互场景。

通过调整semantic_punctuation_enabled参数，可以灵活切换语音识别的断句方式以适应不同场景需求。

max_sentence_silence

int

1300

否

设置VAD（Voice Activity Detection，语音活动检测）断句的静音时长阈值（单位为ms）。

当一段语音后的静音时长超过该阈值时，系统会判定该句子已结束。

参数范围为200ms至6000ms，默认值为1300ms。

该参数仅在semantic_punctuation_enabled参数为false（VAD断句）时生效。

multi_threshold_mode_enabled

bool

False

否

该开关打开时（true）可以防止VAD断句切割过长。默认关闭。

该参数仅在semantic_punctuation_enabled参数为false（VAD断句）时生效。

punctuation_prediction_enabled

bool

True

否

设置是否在识别结果中自动添加标点：

true（默认）：是，不支持修改。

heartbeat

bool

False

否

当需要与服务端保持长连接时，可通过该开关进行控制：

true：在持续发送静音音频的情况下，可保持与服务端的连接不中断。

false（默认）：即使持续发送静音音频，连接也将在60秒后因超时而断开。

静音音频指的是在音频文件或数据流中没有声音信号的内容。静音音频可以通过多种方法生成，例如使用音频编辑软件如Audacity或Adobe Audition，或者通过命令行工具如FFmpeg。

使用该字段时，SDK版本不能低于1.23.1。

callback

RecognitionCallback

-

否

回调接口（RecognitionCallback）。

关键接口
Recognition类
Recognition通过“from dashscope.audio.asr import *”方式引入。




成员方法

方法签名

说明

call

 
def call(self, file: str, phrase_id: str = None, **kwargs) -> RecognitionResult
基于本地文件的同步调用，该方法会阻塞当前线程直到全部音频读完，该方法要求所识别文件具有可读权限。

识别结果以RecognitionResult类型数据返回。

start

 
def start(self, phrase_id: str = None, **kwargs)
开始语音识别。

基于回调形式的流式实时识别，该方法不会阻塞当前线程。需要配合send_audio_frame和stop使用。

send_audio_frame

 
def send_audio_frame(self, buffer: bytes)
推送音频。每次推送的音频流不宜过大或过小，建议每包音频时长为100ms左右，大小在1KB~16KB之间。

识别结果通过回调接口（RecognitionCallback）的on_event方法获取。

stop

 
def stop(self)
停止语音识别，阻塞到服务将收到的音频都识别后结束任务。

get_last_request_id

 
def get_last_request_id(self)
获取request_id，在构造函数调用（创建对象）后可以使用。

get_first_package_delay

 
def get_first_package_delay(self)
获取首包延迟，从发送第一包音频到收到首包识别结果延迟，在任务完成后使用。

get_last_package_delay

 
def get_last_package_delay(self)
获得尾包延迟，发送stop指令到最后一包识别结果下发耗时，在任务完成后使用。

get_response

 
def get_response(self)
获取最后一次报文，可以用于获取task-failed报错。

回调接口（RecognitionCallback）
流式调用时，服务端会通过回调的方式，将关键流程信息和数据返回给客户端。您需要实现回调方法，处理服务端返回的信息或者数据。

点击查看示例





方法

参数

返回值

描述

 
def on_open(self) -> None
无

无

当和服务端建立连接完成后，该方法立刻被回调。

 
def on_event(self, result: RecognitionResult) -> None
result：识别结果（RecognitionResult）

无

当服务有回复时会被回调。

 
def on_complete(self) -> None
无

无

当所有识别结果全部返回后进行回调。

 
def on_error(self, result: RecognitionResult) -> None
result：识别结果（RecognitionResult）

无

发生异常时该方法被回调。

 
def on_close(self) -> None
无

无

当服务已经关闭连接后进行回调。

响应结果
识别结果（RecognitionResult）
RecognitionResult代表流式调用中一次实时识别或同步调用的识别结果。




成员方法

方法签名

说明

get_sentence

 
def get_sentence(self) -> Union[Dict[str, Any], List[Any]]
获取当前识别的句子及时间戳信息。回调中返回的是单句信息，所以此方法返回类型为Dict[str, Any]。

详情请参见单句信息（Sentence）。

get_request_id

 
def get_request_id(self) -> str
获取请求的request_id。

is_sentence_end

 
@staticmethod
def is_sentence_end(sentence: Dict[str, Any]) -> bool
判断给定句子是否已经结束。

单句信息（Sentence）
Sentence类成员如下：




参数

类型

说明

begin_time

int

句子开始时间，单位为ms。

end_time

int

句子结束时间，单位为ms。

text

str

识别文本。

words

字时间戳信息（Word）的list集合

字时间戳信息。

字时间戳信息（Word）
Word类成员如下：




参数

类型

说明

begin_time

int

字开始时间，单位为ms。

end_time

int

字结束时间，单位为ms。

text

str

字。

punctuation

str

标点。

错误码
如遇报错问题，请参见错误信息进行排查。

若问题仍未解决，请加入开发者群反馈遇到的问题，并提供Request ID，以便进一步排查问题。

常见问题
功能特性
Q：在长时间静默的情况下，如何保持与服务端长连接？
将请求参数heartbeat设置为true，并持续向服务端发送静音音频。

静音音频指的是在音频文件或数据流中没有声音信号的内容。静音音频可以通过多种方法生成，例如使用音频编辑软件如Audacity或Adobe Audition，或者通过命令行工具如FFmpeg。

Q：如何将音频格式转换为满足要求的格式？
可使用FFmpeg工具，更多用法请参见FFmpeg官网。

 
# 基础转换命令（万能模板）
# -i，作用：输入文件路径，常用值示例：audio.wav
# -c:a，作用：音频编码器，常用值示例：aac, libmp3lame, pcm_s16le
# -b:a，作用：比特率（音质控制），常用值示例：192k, 320k
# -ar，作用：采样率，常用值示例：44100 (CD), 48000, 16000
# -ac，作用：声道数，常用值示例：1(单声道), 2(立体声)
# -y，作用：覆盖已存在文件(无需值)
ffmpeg -i input_audio.ext -c:a 编码器名 -b:a 比特率 -ar 采样率 -ac 声道数 output.ext

# 例如：WAV → MP3（保持原始质量）
ffmpeg -i input.wav -c:a libmp3lame -q:a 0 output.mp3
# 例如：MP3 → WAV（16bit PCM标准格式）
ffmpeg -i input.mp3 -c:a pcm_s16le -ar 44100 -ac 2 output.wav
# 例如：M4A → AAC（提取/转换苹果音频）
ffmpeg -i input.m4a -c:a copy output.aac  # 直接提取不重编码
ffmpeg -i input.m4a -c:a aac -b:a 256k output.aac  # 重编码提高质量
# 例如：FLAC无损 → Opus（高压缩）
ffmpeg -i input.flac -c:a libopus -b:a 128k -vbr on output.opus
Q：如何识别本地文件（录音文件）？
识别本地文件有两种方式：

直接传入本地文件路径：此种方式在最终识别结束后获取完整识别结果，不适合即时反馈的场景。

参见同步调用，在Recognition类的call方法中传入文件路径对录音文件直接进行识别。

将本地文件转成二进制流进行识别：此种方式一边识别文件一边流式获取识别结果，适合即时反馈的场景。

参见流式调用，通过Recognition类的send_audio_frame方法向服务端发送二进制流对其进行识别。

故障排查
Q：无法识别语音（无识别结果）是什么原因？
请检查请求参数中的音频格式（format）和采样率（sampleRate/sample_rate）设置是否正确且符合参数约束。以下为常见错误示例：

音频文件扩展名为 .wav，但实际为 MP3 格式，而请求参数 format 设置为 mp3（参数设置错误）。

音频采样率为 3600Hz，但请求参数 sampleRate/sample_rate 设置为 48000（参数设置错误）。

可以使用ffprobe工具获取音频的容器、编码、采样率、声道等信息：

 
ffprobe -v error -show_entries format=format_name -show_entries stream=codec_name,sample_rate,channels -of default=noprint_wrappers=1 input.xxx
若以上检查均无问题，可通过定制热词提升对特定词语的识别效果。