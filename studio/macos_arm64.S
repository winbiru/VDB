// Phát triển từ V++ scripts/ASM/macos/vpp_graphics_arm64.S (MIT).
// Cửa sổ Cocoa/WKWebView của VDB. ASM chỉ nối ABI macOS; SQL chạy trong V++.
// argv: URL phiên, tiêu đề UTF-8, rộng, cao, URL gốc.
.text
.p2align 2
.macro DIA_CHI reg, sym
    adrp \reg, \sym@PAGE
    add \reg, \reg, \sym@PAGEOFF
.endm
.macro LOP sym
    DIA_CHI x0, \sym
    bl _objc_getClass
.endm
.macro CHON sym
    DIA_CHI x0, \sym
    bl _sel_registerName
    mov x1, x0
.endm

// Đóng cửa sổ qua quy trình lưu phiên của NSApplication.
Ldong:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    LOP Lnsapp
    mov x8, x0
    stp x8, xzr, [sp, #-16]!
    CHON Lshared
    ldp x0, xzr, [sp], #16
    bl _objc_msgSend
    stp x0, xzr, [sp, #-16]!
    CHON Lterminate
    ldp x0, xzr, [sp], #16
    mov x2, #0
    bl _objc_msgSend
    mov w0, #0 // windowShouldClose: chờ applicationShouldTerminate:
    ldp x29, x30, [sp], #16
    ret

// WKScriptMessageHandler: lưu SQL/CSV bằng hộp thoại hệ thống.
// Chỉ nhận dữ liệu từ tài liệu chính của Studio.
Lsu_kien:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    mov x19, x3
    CHON Lframeinfo
    mov x0, x19
    bl _objc_msgSend
    mov x20, x0
    CHON Lmainframe
    mov x0, x20
    bl _objc_msgSend
    cbz w0, Lsave_done
    CHON Lmessagename
    mov x0, x19
    bl _objc_msgSend
    mov x20, x0
    CHON Lutf8
    mov x0, x20
    bl _objc_msgSend
    cbz x0, Lsave_done
    mov x20, x0
    mov x0, x20
    DIA_CHI x1, Lcatalogchannel
    bl _strcmp
    cbz w0, Lcatalog_pick
    mov x0, x20
    DIA_CHI x1, Lquitchannel
    bl _strcmp
    cbz w0, Lquit_reply
    mov x0, x20
    DIA_CHI x1, Lopenchannel
    bl _strcmp
    cbz w0, Lsql_open
    mov x0, x20
    DIA_CHI x1, Lmenustatechannel
    bl _strcmp
    cbz w0, Lmenu_state
    mov x0, x20
    DIA_CHI x1, Lchannel
    bl _strcmp
    cbnz w0, Lsave_done
    CHON Lbody
    mov x0, x19
    bl _objc_msgSend
    mov x19, x0
    LOP Ldictionary
    mov x20, x0
    CHON Liskind
    mov x0, x19
    mov x2, x20
    bl _objc_msgSend
    cbz w0, Lsave_failed
    LOP Lstring
    mov x20, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lnamekey
    bl _objc_msgSend
    mov x21, x0
    CHON Lobjectkey
    mov x0, x19
    mov x2, x21
    bl _objc_msgSend
    mov x21, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Ltextkey
    bl _objc_msgSend
    mov x22, x0
    CHON Lobjectkey
    mov x0, x19
    mov x2, x22
    bl _objc_msgSend
    mov x22, x0
    CHON Liskind
    mov x0, x21
    mov x2, x20
    bl _objc_msgSend
    cbz w0, Lsave_failed
    CHON Liskind
    mov x0, x22
    mov x2, x20
    bl _objc_msgSend
    cbz w0, Lsave_failed
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lfilekey
    bl _objc_msgSend
    mov x23, x0
    CHON Lobjectkey
    mov x0, x19
    mov x2, x23
    bl _objc_msgSend
    mov x19, x0
    CHON Liskind
    mov x0, x19
    mov x2, x20
    bl _objc_msgSend
    cbnz w0, Lsave_cached
    mov x19, #0
    b Lsave_choose
Lsave_cached:
    CHON Lobjectkey
    DIA_CHI x8, Lfile_urls
    ldr x0, [x8]
    mov x2, x19
    bl _objc_msgSend
    cbz x0, Lsave_choose
    mov x24, x0
    b Lsave_write
Lsave_choose:
    LOP Lsavepanel
    mov x23, x0
    CHON Lsavepanelnew
    mov x0, x23
    bl _objc_msgSend
    mov x23, x0
    CHON Lsetfilename
    mov x0, x23
    mov x2, x21
    bl _objc_msgSend
    CHON Lrunmodal
    mov x0, x23
    bl _objc_msgSend
    cmp x0, #1 // NSModalResponseOK
    b.ne Lsave_failed
    CHON Lpanelurl
    mov x0, x23
    bl _objc_msgSend
    mov x24, x0
Lsave_write:
    CHON Lwritetourl
    mov x0, x22
    mov x2, x24
    mov x3, #1 // atomic
    mov x4, #4 // UTF-8
    mov x5, #0
    bl _objc_msgSend
    cbnz w0, Lsave_success
    LOP Lalert
    mov x23, x0
    CHON Lnew
    mov x0, x23
    bl _objc_msgSend
    mov x23, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lsaveerror
    bl _objc_msgSend
    mov x24, x0
    CHON Lalerttext
    mov x0, x23
    mov x2, x24
    bl _objc_msgSend
    CHON Lrunmodal
    mov x0, x23
    bl _objc_msgSend
    CHON Lrelease
    mov x0, x23
    bl _objc_msgSend
Lsave_failed:
    DIA_CHI x0, Lsavefailjs
    bl Leval_utf8
    b Lsave_done
Lsave_success:
    cbz x19, Lsave_csv_success
    CHON Lsetobjectkey
    DIA_CHI x8, Lfile_urls
    ldr x0, [x8]
    mov x2, x24
    mov x3, x19
    bl _objc_msgSend
    CHON Llastcomponent
    mov x0, x24
    bl _objc_msgSend
    bl Lencode_text
    cbz x0, Lsave_csv_success
    mov x24, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lsaveprefix
    bl _objc_msgSend
    mov x23, x0
    CHON Lappend
    mov x0, x23
    mov x2, x24
    bl _objc_msgSend
    mov x23, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lcatalogsuffix
    bl _objc_msgSend
    mov x24, x0
    CHON Lappend
    mov x0, x23
    mov x2, x24
    bl _objc_msgSend
    bl Leval_string
    b Lsave_done
Lsave_csv_success:
    DIA_CHI x0, Lsaveokjs
    bl Leval_utf8
    b Lsave_done

// NSString -> base64 UTF-8; keeps filenames and SQL out of executable JS.
Lencode_text:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    mov x19, x0
    CHON Ldataencoding
    mov x0, x19
    mov x2, #4
    bl _objc_msgSend
    mov x19, x0
    CHON Lbase64
    mov x0, x19
    mov x2, #0
    bl _objc_msgSend
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// Open SQL in a native panel. Store URL only after a successful UTF-8 read.
Lsql_open:
    CHON Lbody
    mov x0, x19
    bl _objc_msgSend
    mov x19, x0
    LOP Lstring
    mov x20, x0
    CHON Liskind
    mov x0, x19
    mov x2, x20
    bl _objc_msgSend
    cbz w0, Lsql_open_failed
    LOP Lopenpanel
    mov x21, x0
    CHON Lopenpanelnew
    mov x0, x21
    bl _objc_msgSend
    mov x21, x0
    CHON Lsetmultiple
    mov x0, x21
    mov x2, #0
    bl _objc_msgSend
    CHON Lsetdirectories
    mov x0, x21
    mov x2, #0
    bl _objc_msgSend
    CHON Lsetfiles
    mov x0, x21
    mov x2, #1
    bl _objc_msgSend
    CHON Lrunmodal
    mov x0, x21
    bl _objc_msgSend
    cmp x0, #1
    b.ne Lsql_open_failed
    CHON Lpanelurl
    mov x0, x21
    bl _objc_msgSend
    mov x22, x0
    CHON Lreadurl
    mov x0, x20
    mov x2, x22
    mov x3, #4
    mov x4, #0
    bl _objc_msgSend
    cbz x0, Lsql_read_failed
    bl Lencode_text
    cbz x0, Lsql_read_failed
    mov x23, x0
    CHON Llastcomponent
    mov x0, x22
    bl _objc_msgSend
    bl Lencode_text
    cbz x0, Lsql_read_failed
    mov x24, x0
    CHON Lsetobjectkey
    DIA_CHI x8, Lfile_urls
    ldr x0, [x8]
    mov x2, x22
    mov x3, x19
    bl _objc_msgSend
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lopenprefix
    bl _objc_msgSend
    mov x21, x0
    CHON Lappend
    mov x0, x21
    mov x2, x24
    bl _objc_msgSend
    mov x21, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lopenmiddle
    bl _objc_msgSend
    mov x24, x0
    CHON Lappend
    mov x0, x21
    mov x2, x24
    bl _objc_msgSend
    mov x21, x0
    CHON Lappend
    mov x0, x21
    mov x2, x23
    bl _objc_msgSend
    mov x21, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lcatalogsuffix
    bl _objc_msgSend
    mov x24, x0
    CHON Lappend
    mov x0, x21
    mov x2, x24
    bl _objc_msgSend
    bl Leval_string
    b Lsave_done
Lsql_read_failed:
    DIA_CHI x0, Lopenerrorjs
    bl Leval_utf8
    b Lsave_done
Lsql_open_failed:
    DIA_CHI x0, Lopenfailjs
    bl Leval_utf8
    b Lsave_done

// Menu state comes only from the main Studio frame.
Lmenu_state:
    CHON Lbody
    mov x0, x19
    bl _objc_msgSend
    mov x19, x0
    LOP Lnumber
    mov x20, x0
    CHON Liskind
    mov x0, x19
    mov x2, x20
    bl _objc_msgSend
    cbz w0, Lsave_done
    CHON Lunsignedlonglong
    mov x0, x19
    bl _objc_msgSend
    DIA_CHI x8, Lmenu_mask
    str x0, [x8]
    b Lsave_done

// Chọn đường dẫn catalog, không ghi dữ liệu trong hộp thoại.
Lcatalog_pick:
    CHON Lbody
    mov x0, x19
    bl _objc_msgSend
    mov x22, x0
    LOP Lstring
    mov x20, x0
    CHON Liskind
    mov x0, x22
    mov x2, x20
    bl _objc_msgSend
    cbz w0, Lsave_done
    CHON Lutf8
    mov x0, x22
    bl _objc_msgSend
    cbz x0, Lsave_done
    mov x22, x0
    DIA_CHI x1, Lnewmode
    bl _strcmp
    cbz w0, Lcatalog_new
    mov x0, x22
    DIA_CHI x1, Lexistingmode
    bl _strcmp
    cbnz w0, Lsave_done
    LOP Lopenpanel
    mov x23, x0
    CHON Lopenpanelnew
    mov x0, x23
    bl _objc_msgSend
    mov x23, x0
    CHON Lsetmultiple
    mov x0, x23
    mov x2, #0
    bl _objc_msgSend
    CHON Lsetdirectories
    mov x0, x23
    mov x2, #0
    bl _objc_msgSend
    CHON Lsetfiles
    mov x0, x23
    mov x2, #1
    bl _objc_msgSend
    b Lcatalog_modal
Lcatalog_new:
    LOP Lsavepanel
    mov x23, x0
    CHON Lsavepanelnew
    mov x0, x23
    bl _objc_msgSend
    mov x23, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lcatalogfilename
    bl _objc_msgSend
    mov x24, x0
    CHON Lsetfilename
    mov x0, x23
    mov x2, x24
    bl _objc_msgSend
Lcatalog_modal:
    CHON Lrunmodal
    mov x0, x23
    bl _objc_msgSend
    cmp x0, #1
    b.ne Lcatalog_cancel
    CHON Lpanelurl
    mov x0, x23
    bl _objc_msgSend
    mov x24, x0
    CHON Lpath
    mov x0, x24
    bl _objc_msgSend
    mov x24, x0
    CHON Ldataencoding
    mov x0, x24
    mov x2, #4
    bl _objc_msgSend
    mov x24, x0
    CHON Lbase64
    mov x0, x24
    mov x2, #0
    bl _objc_msgSend
    cbz x0, Lcatalog_cancel
    mov x24, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lcatalogprefix
    bl _objc_msgSend
    mov x23, x0
    CHON Lappend
    mov x0, x23
    mov x2, x24
    bl _objc_msgSend
    mov x23, x0
    CHON Lfromutf8
    mov x0, x20
    DIA_CHI x2, Lcatalogsuffix
    bl _objc_msgSend
    mov x24, x0
    CHON Lappend
    mov x0, x23
    mov x2, x24
    bl _objc_msgSend
    bl Leval_string
    b Lsave_done
Lcatalog_cancel:
    DIA_CHI x0, Lcatalogcanceljs
    bl Leval_utf8
    b Lsave_done
Lquit_reply:
    CHON Lbody
    mov x0, x19
    bl _objc_msgSend
    mov x20, x0
    LOP Lnumber
    mov x21, x0
    CHON Liskind
    mov x0, x20
    mov x2, x21
    bl _objc_msgSend
    cbz w0, Lsave_done
    CHON Lboolvalue
    mov x0, x20
    bl _objc_msgSend
    bl Lfinish_quit
Lsave_done:
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

// x0: chuỗi UTF-8 / NSString gửi vào web view hiện tại.
Leval_utf8:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    mov x19, x0
    LOP Lstring
    mov x8, x0
    stp x8, xzr, [sp, #-16]!
    CHON Lfromutf8
    ldp x0, xzr, [sp], #16
    mov x2, x19
    bl _objc_msgSend
    bl Leval_string
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
Leval_string:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    mov x19, x0
    CHON Levaluate
    DIA_CHI x8, Lview
    ldr x0, [x8]
    mov x2, x19
    mov x3, #0
    bl _objc_msgSend
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// Cmd+Q và nút đóng đợi phản hồi lưu workspace trước khi thoát.
Lshould_quit:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    mov x19, x0
    DIA_CHI x8, Lquit_pending
    mov w9, #1
    str w9, [x8]
    DIA_CHI x0, Lquitjs
    bl Leval_utf8
    // Nếu web process không trả lời, hủy thoát để tránh mất bản nháp.
    CHON Lperform_after
    mov x0, x19
    stp x0, x1, [sp, #-16]!
    CHON Lquit_timeout_selector
    mov x2, x1
    ldp x0, x1, [sp], #16
    mov x3, #0
    fmov d0, #15.0
    bl _objc_msgSend
    mov x0, #2 // NSTerminateLater
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
Lquit_timeout:
    mov x0, #0
    b Lfinish_quit
Lfinish_quit:
    stp x29, x30, [sp, #-48]!
    stp x19, x20, [sp, #16]
    mov x19, x0
    DIA_CHI x8, Lquit_pending
    ldr w9, [x8]
    cbz w9, Lquit_done
    str wzr, [x8]
    LOP Lobject
    mov x20, x0
    CHON Lcancel_after
    mov x0, x20
    DIA_CHI x8, Ldelegate_instance
    ldr x2, [x8]
    bl _objc_msgSend
    LOP Lnsapp
    mov x20, x0
    CHON Lshared
    mov x0, x20
    bl _objc_msgSend
    mov x20, x0
    CHON Lreply_quit
    mov x0, x20
    mov x2, x19
    bl _objc_msgSend
Lquit_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// WKUIDelegate: hộp thoại mở tệp cho input[type=file].
Lopen_file:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x5 // completion block
    mov x20, x3 // WKOpenPanelParameters
    mov x21, x4 // frame
    mov x22, #0
    CHON Lmainframe
    mov x0, x21
    bl _objc_msgSend
    cbz w0, Lopen_done
    LOP Lopenpanel
    mov x21, x0
    CHON Lopenpanelnew
    mov x0, x21
    bl _objc_msgSend
    mov x21, x0
    CHON Lallowsmultiple
    mov x0, x20
    bl _objc_msgSend
    mov x22, x0
    CHON Lsetmultiple
    mov x0, x21
    mov x2, x22
    bl _objc_msgSend
    mov x22, #0
    CHON Lrunmodal
    mov x0, x21
    bl _objc_msgSend
    cmp x0, #1
    b.ne Lopen_done
    CHON Lpanelurls
    mov x0, x21
    bl _objc_msgSend
    mov x22, x0
Lopen_done:
    mov x0, x19
    mov x1, x22
    ldr x8, [x19, #16] // block invoke
    blr x8
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// WKNavigationDelegate: giới hạn điều hướng vào đúng HTTP origin cục bộ.
Lnavigation:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x4 // decision block
    mov x20, x3
    CHON Lrequest
    mov x0, x20
    bl _objc_msgSend
    mov x20, x0
    CHON Lpanelurl
    mov x0, x20
    bl _objc_msgSend
    mov x20, x0
    CHON Labsurl
    mov x0, x20
    bl _objc_msgSend
    mov x20, x0
    DIA_CHI x21, Lorigin
    ldr x21, [x21]
    CHON Lprefix
    mov x0, x20
    mov x2, x21
    bl _objc_msgSend
    and x1, x0, #1 // WKNavigationActionPolicyAllow / Cancel
    mov x0, x19
    ldr x8, [x19, #16]
    blr x8
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// NSMenu: x0 menu, x1 UTF-8 title, x2 selector name (or null), x3 key.
Lmenu_item:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    mov x19, x0
    mov x20, x1
    mov x21, x2
    mov x22, x3
    LOP Lstring
    mov x23, x0
    CHON Lfromutf8
    mov x0, x23
    mov x2, x20
    bl _objc_msgSend
    mov x20, x0
    CHON Lfromutf8
    mov x0, x23
    mov x2, x22
    bl _objc_msgSend
    mov x22, x0
    cbz x21, Lmenu_add
    mov x0, x21
    bl _sel_registerName
    mov x21, x0
Lmenu_add:
    CHON Laddmenuitem
    mov x0, x19
    mov x2, x20
    mov x3, x21
    mov x4, x22
    bl _objc_msgSend
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

// x0 main menu, x1 title -> submenu.
Lsubmenu:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0
    mov x2, #0
    DIA_CHI x3, Lempty
    bl Lmenu_item
    mov x20, x0
    LOP Lmenu
    mov x21, x0
    CHON Lnew
    mov x0, x21
    bl _objc_msgSend
    mov x21, x0
    CHON Lmenutitle
    mov x0, x20
    bl _objc_msgSend
    mov x22, x0
    CHON Ltitle
    mov x0, x21
    mov x2, x22
    bl _objc_msgSend
    CHON Lsetsubmenu
    mov x0, x19
    mov x2, x21
    mov x3, x20
    bl _objc_msgSend
    mov x0, x21
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

.macro MENU_ITEM menu, title, action, key
    mov x0, \menu
    DIA_CHI x1, \title
    DIA_CHI x2, \action
    DIA_CHI x3, \key
    bl Lmenu_item
.endm

// AppKit asks the delegate whether a menu action is available.
Lvalidate_menu:
    stp x29, x30, [sp, #-48]!
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov x19, x2
    CHON Ltag
    mov x0, x19
    bl _objc_msgSend
    mov x20, x0
    cmp x20, #32
    b.hs Lmenu_disabled
    cmp x20, #26
    b.lo Lmenu_tag_valid
    cmp x20, #30
    b.lo Lmenu_disabled
Lmenu_tag_valid:
    DIA_CHI x8, Lmenu_mask
    ldr x21, [x8]
    cmp x20, #8
    b.lo Lmenu_enabled_bit
    cmp x20, #11
    b.hi Lmenu_enabled_bit
    // View tags 8..11 correspond to visibility bits 26..29.
    CHON Lsetmenustate
    add x8, x20, #18
    lsrv x8, x21, x8
    and x2, x8, #1
    mov x0, x19
    bl _objc_msgSend
Lmenu_enabled_bit:
    lsrv x8, x21, x20
    and w0, w8, #1
    b Lvalidate_done
Lmenu_disabled:
    mov w0, #0
Lvalidate_done:
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

Lmenu_action:
    stp x29, x30, [sp, #-32]!
    str x19, [sp, #16]
    mov x19, x2
    bl Lvalidate_menu
    cbz w0, Lmenu_action_done
    CHON Ltag
    mov x0, x19
    bl _objc_msgSend
    DIA_CHI x8, Lmenu_scripts
    ldr x0, [x8, x0, lsl #3]
    bl Leval_utf8
Lmenu_action_done:
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// x0 submenu, x1 title, x2 tag. Use explicit delegate target.
Lstudio_menu_item:
    stp x29, x30, [sp, #-48]!
    stp x19, x20, [sp, #16]
    str x21, [sp, #32]
    mov x19, x2
    mov x21, x4
    DIA_CHI x2, Lmenuactionselector
    bl Lmenu_item
    mov x20, x0
    CHON Lsettag
    mov x0, x20
    mov x2, x19
    bl _objc_msgSend
    CHON Lsetkeymodifiers
    mov x0, x20
    mov x2, x21
    bl _objc_msgSend
    CHON Lsettarget
    mov x0, x20
    DIA_CHI x8, Ldelegate_instance
    ldr x2, [x8]
    bl _objc_msgSend
    ldr x21, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

.macro STUDIO_ITEM title, tag, key=Lempty, modifiers=1048576
    mov x0, x22
    DIA_CHI x1, \title
    mov x2, #\tag
    DIA_CHI x3, \key
    mov x4, #\modifiers
    bl Lstudio_menu_item
.endm
.macro STUDIO_MENU title
    mov x0, x23
    DIA_CHI x1, \title
    bl Lsubmenu
    mov x22, x0
.endm

// x0 application. Existing app/Edit menus and standard responder actions.
Lsetup_menu:
    stp x29, x30, [sp, #-64]!
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    mov x20, x0
    LOP Lmenu
    mov x23, x0
    CHON Lnew
    mov x0, x23
    bl _objc_msgSend
    mov x23, x0
    STUDIO_MENU Lappmenu
    STUDIO_ITEM Lpreferencesmenu, 24
    MENU_ITEM x22, Lquitmenu, Lterminate, Lkeyq
    STUDIO_MENU Lfilemenu
    STUDIO_ITEM Lnewquerymenu, 2, Lkeyn
    STUDIO_ITEM Lopenquerymenu, 3, Lkeyo
    STUDIO_ITEM Lsavequerymenu, 4, Lkeys
    STUDIO_ITEM Lsaveasmenu, 5, Lkeys, 1179648
    STUDIO_ITEM Lclosetabmenu, 6, Lkeyw
    STUDIO_MENU Leditmenu
    STUDIO_ITEM Lundomenu, 30, Lkeyz
    STUDIO_ITEM Lredomenu, 31, Lkeyz, 1179648
    MENU_ITEM x22, Lcutmenu, Lcut, Lkeyx
    MENU_ITEM x22, Lcopymenu, Lcopy, Lkeyc
    MENU_ITEM x22, Lpastemenu, Lpaste, Lkeyv
    MENU_ITEM x22, Lselectmenu, Lselectall, Lkeya
    STUDIO_ITEM Lfindmenu, 7, Lkeyf
    STUDIO_MENU Lviewmenu
    STUDIO_ITEM Lnavmenu, 8
    STUDIO_ITEM Linfomenu, 9
    STUDIO_ITEM Lrightmenu, 10
    STUDIO_ITEM Loutputmenu, 11
    STUDIO_ITEM Lresetmenu, 12
    STUDIO_MENU Lquerymenu
    STUDIO_ITEM Lrunallmenu, 13
    STUDIO_ITEM Lrunselectionmenu, 14
    STUDIO_ITEM Lruncurrentmenu, 15
    STUDIO_MENU Ldbmenu
    STUDIO_ITEM Lhomemenu, 0
    STUDIO_ITEM Lconnectmenu, 1
    STUDIO_ITEM Lrefreshmenu, 16
    STUDIO_ITEM Lcreatedbmenu, 17
    STUDIO_ITEM Lcreatetablemenu, 18
    STUDIO_ITEM Lsearchmenu, 19
    STUDIO_ITEM Lstructuremenu, 23
    STUDIO_MENU Ltoolsmenu
    STUDIO_ITEM Limportmenu, 25
    STUDIO_ITEM Lexportmenu, 20
    STUDIO_ITEM Lpreferencesmenu, 24
    STUDIO_MENU Lhelpmenu
    STUDIO_ITEM Lsqlhelpmenu, 21
    STUDIO_ITEM Laboutmenu, 22
    CHON Lsetmainmenu
    mov x0, x20
    mov x2, x23
    bl _objc_msgSend
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

.globl _main
.p2align 2
_main:
    stp x29, x30, [sp, #-112]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    stp x25, x26, [sp, #64]
    stp x27, x28, [sp, #80]
    mov x19, x1
    cmp w0, #2
    b.ne Ltham_so
    ldr x0, [x19, #8]
    DIA_CHI x1, Lcheck
    bl _strcmp
    cbnz w0, Lloi
    DIA_CHI x0, Lversion
    bl _puts
    mov w0, #0
    b Lxong
Ltham_so:
    cmp w0, #6
    b.ne Lloi
    ldr x0, [x19, #24]
    bl _atoi
    cmp w0, #1
    b.lt Lloi
    cmp w0, #16384
    b.gt Lloi
    mov w27, w0
    ldr x0, [x19, #32]
    bl _atoi
    cmp w0, #1
    b.lt Lloi
    cmp w0, #16384
    b.gt Lloi
    mov w28, w0
    bl _objc_autoreleasePoolPush
    str x0, [sp, #96]
    LOP Lnsapp
    mov x20, x0
    CHON Lshared
    mov x0, x20
    bl _objc_msgSend
    mov x20, x0
    CHON Lpolicy
    mov x0, x20
    mov x2, #0
    bl _objc_msgSend

    // Đăng ký lớp delegate cho cả NSWindow và WKScriptMessageHandler.
    LOP Lobject
    DIA_CHI x1, Ldelegate_name
    mov x2, #0
    bl _objc_allocateClassPair
    cbz x0, Lloi_pool
    mov x21, x0
    CHON Lclose
    mov x0, x21
    DIA_CHI x2, Ldong
    DIA_CHI x3, Lclose_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    CHON Lshouldquit
    mov x0, x21
    DIA_CHI x2, Lshould_quit
    DIA_CHI x3, Lshouldquit_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    CHON Lquit_timeout_selector
    mov x0, x21
    DIA_CHI x2, Lquit_timeout
    DIA_CHI x3, Ltimeout_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    CHON Lmessage
    mov x0, x21
    DIA_CHI x2, Lsu_kien
    DIA_CHI x3, Lmessage_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    CHON Lopenmethod
    mov x0, x21
    DIA_CHI x2, Lopen_file
    DIA_CHI x3, Lopen_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    CHON Lnavmethod
    mov x0, x21
    DIA_CHI x2, Lnavigation
    DIA_CHI x3, Lnav_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    CHON Lmenuactionselector
    mov x0, x21
    DIA_CHI x2, Lmenu_action
    DIA_CHI x3, Ltimeout_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    CHON Lvalidatemenu
    mov x0, x21
    DIA_CHI x2, Lvalidate_menu
    DIA_CHI x3, Lclose_type
    bl _class_addMethod
    cbz w0, Lloi_pool
    mov x0, x21
    bl _objc_registerClassPair
    CHON Lnew
    mov x0, x21
    bl _objc_msgSend
    mov x21, x0

    DIA_CHI x8, Ldelegate_instance
    str x21, [x8]
    CHON Lsetdelegate
    mov x0, x20
    mov x2, x21
    bl _objc_msgSend

    LOP Lmutabledictionary
    mov x23, x0
    CHON Lnew
    mov x0, x23
    bl _objc_msgSend
    DIA_CHI x8, Lfile_urls
    str x0, [x8]
    mov x0, x20
    bl Lsetup_menu

    // Cửa sổ Cocoa, NSRect truyền qua d0..d3 (AAPCS64 HFA).
    LOP Lwindow
    mov x22, x0
    CHON Lalloc
    mov x0, x22
    bl _objc_msgSend
    mov x22, x0
    CHON Linitwindow
    mov x0, x22
    mov x2, #15 // titled, closable, miniaturizable, resizable
    mov x3, #2  // NSBackingStoreBuffered
    mov x4, #0
    fmov d0, xzr
    fmov d1, xzr
    scvtf d2, w27
    scvtf d3, w28
    bl _objc_msgSend
    cbz x0, Lloi_pool
    mov x22, x0
    CHON Lreleased
    mov x0, x22
    mov x2, #0
    bl _objc_msgSend
    CHON Lsetdelegate
    mov x0, x22
    mov x2, x21
    bl _objc_msgSend

    LOP Lstring
    mov x23, x0
    CHON Lfromutf8
    mov x0, x23
    ldr x2, [x19, #16]
    bl _objc_msgSend
    mov x24, x0
    CHON Ltitle
    mov x0, x22
    mov x2, x24
    bl _objc_msgSend

    // WKWebViewConfiguration và kênh sự kiện JS -> Cocoa.
    LOP Lconfig
    mov x24, x0
    CHON Lnew
    mov x0, x24
    bl _objc_msgSend
    mov x24, x0
    // Kho dữ liệu tạm cho mỗi cửa sổ, không ghi dữ liệu trình duyệt vào hồ sơ người dùng.
    LOP Ldatastore
    mov x25, x0
    CHON Lnonpersistent
    mov x0, x25
    bl _objc_msgSend
    mov x25, x0
    CHON Lsetdatastore
    mov x0, x24
    mov x2, x25
    bl _objc_msgSend
    CHON Lcontroller
    mov x0, x24
    bl _objc_msgSend
    mov x25, x0
    CHON Lfromutf8
    mov x0, x23
    DIA_CHI x2, Lchannel
    bl _objc_msgSend
    mov x26, x0
    CHON Laddhandler
    mov x0, x25
    mov x2, x21
    mov x3, x26
    bl _objc_msgSend

    CHON Lfromutf8
    mov x0, x23
    DIA_CHI x2, Lcatalogchannel
    bl _objc_msgSend
    mov x26, x0
    CHON Laddhandler
    mov x0, x25
    mov x2, x21
    mov x3, x26
    bl _objc_msgSend
    CHON Lfromutf8
    mov x0, x23
    DIA_CHI x2, Lquitchannel
    bl _objc_msgSend
    mov x26, x0
    CHON Laddhandler
    mov x0, x25
    mov x2, x21
    mov x3, x26
    bl _objc_msgSend

    CHON Lfromutf8
    mov x0, x23
    DIA_CHI x2, Lmenustatechannel
    bl _objc_msgSend
    mov x26, x0
    CHON Laddhandler
    mov x0, x25
    mov x2, x21
    mov x3, x26
    bl _objc_msgSend

    CHON Lfromutf8
    mov x0, x23
    DIA_CHI x2, Lopenchannel
    bl _objc_msgSend
    mov x26, x0
    CHON Laddhandler
    mov x0, x25
    mov x2, x21
    mov x3, x26
    bl _objc_msgSend

    LOP Lwebview
    mov x25, x0
    CHON Lalloc
    mov x0, x25
    bl _objc_msgSend
    mov x25, x0
    CHON Linitview
    mov x0, x25
    mov x2, x24
    fmov d0, xzr
    fmov d1, xzr
    scvtf d2, w27
    scvtf d3, w28
    bl _objc_msgSend
    cbz x0, Lloi_pool
    mov x25, x0
    DIA_CHI x8, Lview
    str x25, [x8]
    CHON Lcontent
    mov x0, x22
    mov x2, x25
    bl _objc_msgSend

    CHON Lsetui
    mov x0, x25
    mov x2, x21
    bl _objc_msgSend
    CHON Lsetnav
    mov x0, x25
    mov x2, x21
    bl _objc_msgSend

    // URL gốc được dùng để chặn điều hướng ra ngoài Studio.
    CHON Lfromutf8
    mov x0, x23
    ldr x2, [x19, #40]
    bl _objc_msgSend
    DIA_CHI x8, Lorigin
    str x0, [x8]
    // Nạp HTTP URL sau khi server V++ đã sẵn sàng.
    CHON Lfromutf8
    mov x0, x23
    ldr x2, [x19, #8]
    bl _objc_msgSend
    cbz x0, Lloi_pool
    mov x26, x0
    LOP Lurl
    mov x23, x0
    CHON Lurlwithstring
    mov x0, x23
    mov x2, x26
    bl _objc_msgSend
    cbz x0, Lloi_pool
    mov x26, x0
    LOP Lurlrequest
    mov x23, x0
    CHON Lrequestwithurl
    mov x0, x23
    mov x2, x26
    bl _objc_msgSend
    mov x26, x0
    CHON Lload
    mov x0, x25
    mov x2, x26
    bl _objc_msgSend

    CHON Lcenter
    mov x0, x22
    bl _objc_msgSend
    CHON Lfinishlaunching
    mov x0, x20
    bl _objc_msgSend
    CHON Lshow
    mov x0, x22
    mov x2, #0
    bl _objc_msgSend
    CHON Lactivate
    mov x0, x20
    mov x2, #1
    bl _objc_msgSend
    CHON Lrun
    mov x0, x20
    bl _objc_msgSend
    ldr x0, [sp, #96]
    bl _objc_autoreleasePoolPop
    mov w0, #0
    b Lxong
Lloi_pool:
    ldr x0, [sp, #96]
    bl _objc_autoreleasePoolPop
Lloi:
    mov w0, #2
Lxong:
    ldp x27, x28, [sp, #80]
    ldp x25, x26, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #112
    ret

.section __TEXT,__cstring,cstring_literals
Lcheck: .asciz "--check"
Lversion: .asciz "vdb-studio-macos 1"
Lnsapp: .asciz "NSApplication"
Lobject: .asciz "NSObject"
Lwindow: .asciz "NSWindow"
Lstring: .asciz "NSString"
Lurl: .asciz "NSURL"
Ldatastore: .asciz "WKWebsiteDataStore"
Lnonpersistent: .asciz "nonPersistentDataStore"
Lsetdatastore: .asciz "setWebsiteDataStore:"
Lconfig: .asciz "WKWebViewConfiguration"
Lwebview: .asciz "WKWebView"
Ldelegate_name: .asciz "VDBStudioDelegate"
Lchannel: .asciz "vdbSave"
Lcatalogchannel: .asciz "vdbCatalog"
Lquitchannel: .asciz "vdbQuit"
Lmessagename: .asciz "name"
Lutf8: .asciz "UTF8String"
Lnewmode: .asciz "new"
Lexistingmode: .asciz "existing"
Lcatalogfilename: .asciz "catalog.json"
Lsetdirectories: .asciz "setCanChooseDirectories:"
Lsetfiles: .asciz "setCanChooseFiles:"
Lpath: .asciz "path"
Ldataencoding: .asciz "dataUsingEncoding:"
Lbase64: .asciz "base64EncodedStringWithOptions:"
Lappend: .asciz "stringByAppendingString:"
Lcatalogprefix: .asciz "window.vdbCatalogPicked('"
Lcatalogsuffix: .asciz "')"
Lcatalogcanceljs: .asciz "window.vdbCatalogPicked('')"
Levaluate: .asciz "evaluateJavaScript:completionHandler:"
Lsaveokjs: .asciz "window.vdbFileSaved(true)"
Lsavefailjs: .asciz "window.vdbFileSaved(false)"
Lquitjs: .asciz "window.vdbPrepareQuit ? window.vdbPrepareQuit() : window.webkit.messageHandlers.vdbQuit.postMessage(true)"
Lnumber: .asciz "NSNumber"
Lboolvalue: .asciz "boolValue"
Lshouldquit: .asciz "applicationShouldTerminate:"
Lshouldquit_type: .asciz "Q@:@"
Lquit_timeout_selector: .asciz "vdbQuitTimeout:"
Ltimeout_type: .asciz "v@:@"
Lperform_after: .asciz "performSelector:withObject:afterDelay:"
Lcancel_after: .asciz "cancelPreviousPerformRequestsWithTarget:"
Lreply_quit: .asciz "replyToApplicationShouldTerminate:"
Lshared: .asciz "sharedApplication"
Lpolicy: .asciz "setActivationPolicy:"
Lclose: .asciz "windowShouldClose:"
Lclose_type: .asciz "B@:@"
Lmessage: .asciz "userContentController:didReceiveScriptMessage:"
Lmessage_type: .asciz "v@:@@"
Lbody: .asciz "body"
Lrelease: .asciz "release"
Lalloc: .asciz "alloc"
Lnew: .asciz "new"
Linitwindow: .asciz "initWithContentRect:styleMask:backing:defer:"
Lreleased: .asciz "setReleasedWhenClosed:"
Lsetdelegate: .asciz "setDelegate:"
Lfromutf8: .asciz "stringWithUTF8String:"
Ltitle: .asciz "setTitle:"
Lcontroller: .asciz "userContentController"
Laddhandler: .asciz "addScriptMessageHandler:name:"
Linitview: .asciz "initWithFrame:configuration:"
Lcontent: .asciz "setContentView:"
Lurlwithstring: .asciz "URLWithString:"
Lurlrequest: .asciz "NSURLRequest"
Lrequestwithurl: .asciz "requestWithURL:"
Lload: .asciz "loadRequest:"
Lcenter: .asciz "center"
Lshow: .asciz "makeKeyAndOrderFront:"
Lactivate: .asciz "activateIgnoringOtherApps:"
Lrun: .asciz "run"
Lterminate: .asciz "terminate:"
Ldictionary: .asciz "NSDictionary"
Lframeinfo: .asciz "frameInfo"
Lmainframe: .asciz "isMainFrame"
Liskind: .asciz "isKindOfClass:"
Lnamekey: .asciz "name"
Ltextkey: .asciz "text"
Lobjectkey: .asciz "objectForKey:"
Lsavepanel: .asciz "NSSavePanel"
Lsavepanelnew: .asciz "savePanel"
Lsetfilename: .asciz "setNameFieldStringValue:"
Lrunmodal: .asciz "runModal"
Lpanelurl: .asciz "URL"
Lwritetourl: .asciz "writeToURL:atomically:encoding:error:"
Lalert: .asciz "NSAlert"
Lalerttext: .asciz "setMessageText:"
Lsaveerror: .asciz "Không thể lưu tệp VDB Studio."
Lopenpanel: .asciz "NSOpenPanel"
Lopenpanelnew: .asciz "openPanel"
Lallowsmultiple: .asciz "allowsMultipleSelection"
Lsetmultiple: .asciz "setAllowsMultipleSelection:"
Lpanelurls: .asciz "URLs"
Lopenmethod: .asciz "webView:runOpenPanelWithParameters:initiatedByFrame:completionHandler:"
Lopen_type: .asciz "v@:@@@@?"
Lnavmethod: .asciz "webView:decidePolicyForNavigationAction:decisionHandler:"
Lnav_type: .asciz "v@:@@@?"
Lsetui: .asciz "setUIDelegate:"
Lsetnav: .asciz "setNavigationDelegate:"
Lrequest: .asciz "request"
Labsurl: .asciz "absoluteString"
Lprefix: .asciz "hasPrefix:"
Lmenu: .asciz "NSMenu"
Lmenutitle: .asciz "title"
Laddmenuitem: .asciz "addItemWithTitle:action:keyEquivalent:"
Lsetsubmenu: .asciz "setSubmenu:forItem:"
Lsetmainmenu: .asciz "setMainMenu:"
Lfinishlaunching: .asciz "finishLaunching"
Lempty: .asciz ""
Lappmenu: .asciz "VDB Studio"
Leditmenu: .asciz "Edit"
Lquitmenu: .asciz "Quit VDB Studio"
Lundomenu: .asciz "Undo SQL"
Lcutmenu: .asciz "Cut"
Lcopymenu: .asciz "Copy"
Lpastemenu: .asciz "Paste"
Lselectmenu: .asciz "Select All"
Lundo: .asciz "undo:"
Lcut: .asciz "cut:"
Lcopy: .asciz "copy:"
Lpaste: .asciz "paste:"
Lselectall: .asciz "selectAll:"
Lkeyq: .asciz "q"
Lkeyz: .asciz "z"
Lkeyx: .asciz "x"
Lkeyc: .asciz "c"
Lkeyv: .asciz "v"
Lkeya: .asciz "a"

Lopenchannel: .asciz "vdbOpenSQL"
Lmutabledictionary: .asciz "NSMutableDictionary"
Lsetobjectkey: .asciz "setObject:forKey:"
Lfilekey: .asciz "key"
Llastcomponent: .asciz "lastPathComponent"
Lreadurl: .asciz "stringWithContentsOfURL:encoding:error:"
Lsaveprefix: .asciz "window.vdbFileSaved(true,'"
Lopenprefix: .asciz "window.vdbFileOpened('"
Lopenmiddle: .asciz "','"
Lopenerrorjs: .asciz "window.vdbFileOpened(null,null,true)"
Lopenfailjs: .asciz "window.vdbFileOpened(null)"
Lmenustatechannel: .asciz "vdbMenuState"
Lunsignedlonglong: .asciz "unsignedLongLongValue"
Ltag: .asciz "tag"
Lsettag: .asciz "setTag:"
Lsettarget: .asciz "setTarget:"
Lmenuactionselector: .asciz "vdbMenuAction:"
Lsetkeymodifiers: .asciz "setKeyEquivalentModifierMask:"
Lkeyn: .asciz "n"
Lkeyo: .asciz "o"
Lkeys: .asciz "s"
Lkeyw: .asciz "w"
Lkeyf: .asciz "f"
Lvalidatemenu: .asciz "validateMenuItem:"
Lfilemenu: .asciz "File"
Lviewmenu: .asciz "View"
Lquerymenu: .asciz "Query"
Ldbmenu: .asciz "Database"
Ltoolsmenu: .asciz "Tools"
Lhelpmenu: .asciz "Help"
Lnewquerymenu: .asciz "New Query"
Lopenquerymenu: .asciz "Open SQL"
Lsavequerymenu: .asciz "Save"
Lsaveasmenu: .asciz "Save As"
Lclosetabmenu: .asciz "Close Tab"
Lsetmenustate: .asciz "setState:"
Lredomenu: .asciz "Redo SQL"
Lredo: .asciz "redo:"
Lfindmenu: .asciz "Find / Replace"
Lnavmenu: .asciz "Toggle Navigator"
Linfomenu: .asciz "Toggle Information"
Lrightmenu: .asciz "Toggle SQL Additions"
Loutputmenu: .asciz "Toggle Output"
Lresetmenu: .asciz "Reset Layout"
Lrunallmenu: .asciz "Run All"
Lrunselectionmenu: .asciz "Run Selection"
Lruncurrentmenu: .asciz "Run Current Statement"
Lhomemenu: .asciz "Manage Connections"
Lconnectmenu: .asciz "New Connection"
Lrefreshmenu: .asciz "Refresh Schemas"
Lcreatedbmenu: .asciz "Create Database"
Lcreatetablemenu: .asciz "Create Table"
Lsearchmenu: .asciz "Search Objects"
Lstructuremenu: .asciz "View Table Structure"
Limportmenu: .asciz "Import CSV"
Lexportmenu: .asciz "Export Result CSV"
Lpreferencesmenu: .asciz "Preferences"
Lsqlhelpmenu: .asciz "VDB SQL Help"
Laboutmenu: .asciz "About VDB Studio"
Lmenu_js0: .asciz "window.vdbAction && window.vdbAction(0)"
Lmenu_js1: .asciz "window.vdbAction && window.vdbAction(1)"
Lmenu_js2: .asciz "window.vdbAction && window.vdbAction(2)"
Lmenu_js3: .asciz "window.vdbAction && window.vdbAction(3)"
Lmenu_js4: .asciz "window.vdbAction && window.vdbAction(4)"
Lmenu_js5: .asciz "window.vdbAction && window.vdbAction(5)"
Lmenu_js6: .asciz "window.vdbAction && window.vdbAction(6)"
Lmenu_js7: .asciz "window.vdbAction && window.vdbAction(7)"
Lmenu_js8: .asciz "window.vdbAction && window.vdbAction(8)"
Lmenu_js9: .asciz "window.vdbAction && window.vdbAction(9)"
Lmenu_js10: .asciz "window.vdbAction && window.vdbAction(10)"
Lmenu_js11: .asciz "window.vdbAction && window.vdbAction(11)"
Lmenu_js12: .asciz "window.vdbAction && window.vdbAction(12)"
Lmenu_js13: .asciz "window.vdbAction && window.vdbAction(13)"
Lmenu_js14: .asciz "window.vdbAction && window.vdbAction(14)"
Lmenu_js15: .asciz "window.vdbAction && window.vdbAction(15)"
Lmenu_js16: .asciz "window.vdbAction && window.vdbAction(16)"
Lmenu_js17: .asciz "window.vdbAction && window.vdbAction(17)"
Lmenu_js18: .asciz "window.vdbAction && window.vdbAction(18)"
Lmenu_js19: .asciz "window.vdbAction && window.vdbAction(19)"
Lmenu_js20: .asciz "window.vdbAction && window.vdbAction(20)"
Lmenu_js21: .asciz "window.vdbAction && window.vdbAction(21)"
Lmenu_js22: .asciz "window.vdbAction && window.vdbAction(22)"
Lmenu_js23: .asciz "window.vdbAction && window.vdbAction(23)"
Lmenu_js24: .asciz "window.vdbAction && window.vdbAction(24)"
Lmenu_js25: .asciz "window.vdbAction && window.vdbAction(25)"
Lmenu_js30: .asciz "window.vdbAction && window.vdbAction(30)"
Lmenu_js31: .asciz "window.vdbAction && window.vdbAction(31)"
.data
.p2align 3
Lfile_urls: .quad 0
Lmenu_mask: .quad 0
Lmenu_scripts: .quad Lmenu_js0, Lmenu_js1, Lmenu_js2, Lmenu_js3, Lmenu_js4, Lmenu_js5, Lmenu_js6, Lmenu_js7, Lmenu_js8, Lmenu_js9, Lmenu_js10, Lmenu_js11, Lmenu_js12, Lmenu_js13, Lmenu_js14, Lmenu_js15, Lmenu_js16, Lmenu_js17, Lmenu_js18, Lmenu_js19, Lmenu_js20, Lmenu_js21, Lmenu_js22, Lmenu_js23, Lmenu_js24, Lmenu_js25, 0, 0, 0, 0, Lmenu_js30, Lmenu_js31
Lorigin: .quad 0
Lview: .quad 0
Ldelegate_instance: .quad 0
Lquit_pending: .long 0
.subsections_via_symbols
