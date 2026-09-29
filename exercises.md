# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: ..........................  Mã học viên: ..........................

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> *Câu trả lời của bạn*

deploy lên Railway, quên set AGENT_API_KEY. Nếu Settings có default "changeme", app khởi động với khóa changeme. Ai đó scan internet tìm /ask, thử X-API-Key: changeme → vào được → dùng LLM miễn phí → hóa đơn của tôi sẽ tăng. Nhờ fail fast, container crash ngay → Railway báo đỏ → tôi biết ngay để set biến.

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> *Câu trả lời của bạn*

tests/test_cp3.py::TestAuthentication::test_tra_ve_dung_user_id {"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T05:11:48.687842+00:00", "user_id": "sv-123", "tokens_in": 1, "tokens_out": 34, "cost_usd": 2.055e-05}
PASSED
tests/test_cp3.py::TestAuthentication::test_khong_gui_user_id_thi_thanh_anonymous {"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T05:11:48.715812+00:00", "user_id": "anonymous", "tokens_in": 1, "tokens_out": 34, "cost_usd": 2.055e-05}
PASSED
Hai việc làm được mà print("đã trả lời xong") không làm được:

Lọc theo user: grep '"user_id":"sv-test"' hoặc query bằng log aggregator (Datadog) → biết user nào đang dùng nhiều.

Tính tổng chi phí: cộng trường cost_usd theo thời gian → biết hôm nay tiêu bao nhiêu, user nào tiêu nhiều.
### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```
PS C:\Users\fpt\K4-L3B-NguyenVanBao-L3B202602862-CloudServicesAndDeployment> docker images | Select-String "agent"

agent:multi                                                                c1c92a5be78f        271MB         63.9MB        
agent:single                                                               1d932e74df07       1.73GB          446MB        
day12-agent:prod                                                           36b546624278        271MB         63.9MB        
k4-l3b-nguyenvanbao-l3b202602862-cloudservicesanddeployment-agent:latest   aaa04b79b485        271MB         63.9MB   U
| Bản | Dung lượng |
|-----|-----------|
| agent:single  | 1,73 GB |
| agent:multi  | 271 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> *Câu trả lời của bạn*
> Bản 1-stage dùng base image `python:3.11` đầy đủ (1,73 GB) bao gồm compiler
> (gcc), pip cache, build tools, và nhiều thư viện hệ thống không cần thiết
> khi chạy. Bản multi-stage dùng `python:3.11-slim` (271 MB) cho cả 2 stage,
> đồng thời stage runtime chỉ COPY dependency đã cài từ stage builder — không
> mang theo compiler, pip cache, hay source rác. Ngoài ra, `.dockerignore`
> loại bỏ `.git`, `.venv`, `__pycache__`, `tests/` khỏi build context. Phần
> chênh lệch ~1,5GB chủ yếu là base image đầy đủ và build tools không
> được copy sang stage runtime.

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> *Câu trả lời của bạn*

Layer A (COPY requirements.txt) — cache hit (requirements.txt không đổi)

Layer B (RUN pip install) — cache hit (requirements không đổi)

Layer C (COPY . .) — cache miss (source code đổi) → layer này và sau nó phải chạy lại

Nếu đặt COPY . . lên trước RUN pip install:

Sửa 1 ký tự trong main.py → COPY . . invalidate → RUN pip install cũng invalidate → cài lại toàn bộ thư viện mỗi lần build

Build chậm hơn 30-60 giây mỗi lần

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> *Câu trả lời của bạn*
Lỗ hổng Python
→ attacker chạy code trong container
→ có quyền root
→ khai thác container để escape
→ chiếm quyền cao trên host

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> *Câu trả lời của bạn*
giả sử lúc 00:00:59 gửi 10 request  
thì lúc 00:01:00 gửi 10 request nữa
nên trong 2 giây liên tiếp có thể gửi được tối đa 20 request
### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> *Câu trả lời của bạn*

|                      | Rate Limit                            | Cost Guard                                |
| -------------------- | ------------------------------------- | ----------------------------------------- |
| Mục đích             | Giới hạn **tần suất request**         | Giới hạn **chi phí/tài nguyên tiêu thụ**  |
| Đo cái gì?           | Số request trong một khoảng thời gian | Token, tiền, CPU, GPU, thời gian xử lý... |
| Ví dụ                | ≤ 10 requests/phút                    | ≤ 100k tokens/phút                        |
| Một request nặng/nhẹ | Thường tính như nhau                  | Có thể có chi phí rất khác nhau           |

tình huống mà rate limit cho qua nhưng cost guard phải chặn:
giả sử rate limit là 10 request/minute, cost guard: 100000 token/minute
người dùng gửi 6 request mỗi request 20000 token 
=> mặc dù chỉ gửi 6/10 request nên rate limit cho qua nhưng tổng số token là 120000 vượt quá cost guard nên bị chặn
tình huống mà cost guard cho qua nhưng rate limit phải chặn:
giả sử rate limit là 10 request/minute, cost guard: 100000 token/minute
người dùng gửi 11 request, mỗi request 1000 token
=> mặc dù tổng số token là 11000 nhưng số request đã vượt quá rate limit nên bị chặn
### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> *Câu trả lời của bạn*
Theo đúng thứ tự:

Client gửi request → Load Balancer chuyển tới C1/C2/C3.
Container nhận request → kiểm tra Redis.
Redis mất kết nối → cả 3 container đều không đọc/ghi được rate limit.
Redis timeout → request bị xử lý theo chính sách fallback:
Fail-closed: từ chối request.
Fail-open: cho request đi tiếp, bỏ qua guard.
Redis hoạt động lại sau 30 giây → các container kết nối lại và kiểm tra Redis bình thường.

=> 3 container không giúp tránh lỗi này vì cả 3 cùng phụ thuộc vào một Redis.

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> *Câu trả lời của bạn*

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> *Câu trả lời của bạn*
(.venv) PS C:\Users\fpt\K4-L3B-NguyenVanBao-L3B202602862-CloudServicesAndDeployment> curl https://day12-agent-production-1089.up.railway.app/ready
curl : Internal Server Error
At line:1 char:1
+ curl https://day12-agent-production-1089.up.railway.app/ready
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (System.Net.HttpWebRequest:HttpWebRequest) [Invoke-WebRequest], WebException
    + FullyQualifiedErrorId : WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand
do chưa set agent_api_key trên railway
