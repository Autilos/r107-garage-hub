import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { supabase } from '@/integrations/supabase/client'
import { useToast } from '@/hooks/use-toast'
import { useRef, useState } from 'react'
import {
    Bold,
    Italic,
    List,
    ListOrdered,
    Heading1,
    Heading2,
    Link as LinkIcon,
    Image as ImageIcon,
    Quote,
    Undo,
    Redo,
    Upload,
    Code,
    Loader2
} from 'lucide-react'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogFooter,
} from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

interface RichTextEditorProps {
    content: string | null;
    onChange: (content: string) => void;
}

export function RichTextEditor({ content, onChange }: RichTextEditorProps) {
    const { toast } = useToast()
    const fileInputRef = useRef<HTMLInputElement>(null)
    const [isUploading, setIsUploading] = useState(false)
    const [showImageDialog, setShowImageDialog] = useState(false)
    const [imageUrl, setImageUrl] = useState('')
    const [showHtmlDialog, setShowHtmlDialog] = useState(false)
    const [htmlContent, setHtmlContent] = useState('')

    const editor = useEditor({
        extensions: [
            StarterKit,
            Link.configure({
                openOnClick: false,
                HTMLAttributes: {
                    class: 'text-primary underline cursor-pointer',
                },
            }),
            Image.configure({
                HTMLAttributes: {
                    class: 'rounded-lg max-w-full my-4',
                },
            }),
        ],
        content: content || '',
        editorProps: {
            attributes: {
                class: 'prose prose-sm dark:prose-invert max-w-none min-h-[300px] p-4 focus:outline-none border rounded-b-lg bg-background',
            },
        },
        onUpdate: ({ editor }) => {
            onChange(editor.getHTML())
        },
    })

    if (!editor) {
        return null
    }

    const setLink = () => {
        const previousUrl = editor.getAttributes('link').href
        const url = window.prompt('URL', previousUrl)

        if (url === null) {
            return
        }

        if (url === '') {
            editor.chain().focus().extendMarkRange('link').unsetLink().run()
            return
        }

        editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run()
    }

    const handleFileUpload = async (file: File) => {
        if (!file.type.startsWith('image/')) {
            toast({
                title: 'Błędny typ pliku',
                description: 'Dozwolone są tylko pliki graficzne.',
                variant: 'destructive'
            })
            return
        }

        if (file.size > 5 * 1024 * 1024) {
            toast({
                title: 'Plik za duży',
                description: 'Maksymalny rozmiar pliku to 5MB.',
                variant: 'destructive'
            })
            return
        }

        setIsUploading(true)

        try {
            const fileExt = file.name.split('.').pop()
            const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
            const filePath = `content/${fileName}`

            const { error: uploadError } = await supabase.storage
                .from('article-images')
                .upload(filePath, file)

            if (uploadError) throw uploadError

            const { data: { publicUrl } } = supabase.storage
                .from('article-images')
                .getPublicUrl(filePath)

            editor.chain().focus().setImage({ src: publicUrl }).run()

            toast({ title: 'Zdjęcie zostało dodane' })
        } catch (error: any) {
            toast({
                title: 'Błąd uploadu',
                description: error.message,
                variant: 'destructive'
            })
        } finally {
            setIsUploading(false)
        }
    }

    const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (file) {
            handleFileUpload(file)
        }
        e.target.value = ''
    }

    const addImageFromUrl = () => {
        if (imageUrl.trim()) {
            editor.chain().focus().setImage({ src: imageUrl.trim() }).run()
            setImageUrl('')
            setShowImageDialog(false)
        }
    }

    const insertHtml = () => {
        if (htmlContent.trim()) {
            editor.commands.insertContent(htmlContent)
            setHtmlContent('')
            setShowHtmlDialog(false)
            toast({ title: 'HTML został dodany' })
        }
    }

    return (
        <div className="border rounded-lg">
            <div className="bg-muted/50 p-2 border-b flex flex-wrap gap-1 items-center sticky top-0 z-10 backdrop-blur-sm">
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().toggleBold().run()}
                    className={editor.isActive('bold') ? 'bg-muted' : ''}
                    title="Pogrubienie"
                >
                    <Bold className="h-4 w-4" />
                </Button>
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().toggleItalic().run()}
                    className={editor.isActive('italic') ? 'bg-muted' : ''}
                    title="Kursywa"
                >
                    <Italic className="h-4 w-4" />
                </Button>

                <div className="w-px h-6 bg-border mx-1" />

                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
                    className={editor.isActive('heading', { level: 2 }) ? 'bg-muted' : ''}
                    title="Nagłówek H2"
                >
                    <Heading1 className="h-4 w-4" />
                </Button>
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
                    className={editor.isActive('heading', { level: 3 }) ? 'bg-muted' : ''}
                    title="Nagłówek H3"
                >
                    <Heading2 className="h-4 w-4" />
                </Button>

                <div className="w-px h-6 bg-border mx-1" />

                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().toggleBulletList().run()}
                    className={editor.isActive('bulletList') ? 'bg-muted' : ''}
                    title="Lista punktowana"
                >
                    <List className="h-4 w-4" />
                </Button>
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().toggleOrderedList().run()}
                    className={editor.isActive('orderedList') ? 'bg-muted' : ''}
                    title="Lista numerowana"
                >
                    <ListOrdered className="h-4 w-4" />
                </Button>
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().toggleBlockquote().run()}
                    className={editor.isActive('blockquote') ? 'bg-muted' : ''}
                    title="Cytat"
                >
                    <Quote className="h-4 w-4" />
                </Button>

                <div className="w-px h-6 bg-border mx-1" />

                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={setLink}
                    className={editor.isActive('link') ? 'bg-muted' : ''}
                    title="Dodaj link"
                >
                    <LinkIcon className="h-4 w-4" />
                </Button>
                
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowImageDialog(true)}
                    title="Dodaj zdjęcie (URL)"
                >
                    <ImageIcon className="h-4 w-4" />
                </Button>
                
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isUploading}
                    title="Upload zdjęcia z dysku"
                >
                    {isUploading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Upload className="h-4 w-4" />}
                </Button>

                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileInputChange}
                    className="hidden"
                />

                <div className="w-px h-6 bg-border mx-1" />

                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowHtmlDialog(true)}
                    title="Wstaw HTML"
                >
                    <Code className="h-4 w-4" />
                </Button>

                <div className="w-px h-6 bg-border mx-1" />

                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().undo().run()}
                    disabled={!editor.can().undo()}
                    title="Cofnij"
                >
                    <Undo className="h-4 w-4" />
                </Button>
                <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => editor.chain().focus().redo().run()}
                    disabled={!editor.can().redo()}
                    title="Ponów"
                >
                    <Redo className="h-4 w-4" />
                </Button>
            </div>

            <EditorContent editor={editor} />

            {/* Dialog do dodawania zdjęcia z URL */}
            <Dialog open={showImageDialog} onOpenChange={setShowImageDialog}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Dodaj zdjęcie</DialogTitle>
                    </DialogHeader>
                    <Tabs defaultValue="url" className="w-full">
                        <TabsList className="grid w-full grid-cols-2">
                            <TabsTrigger value="url">Z URL</TabsTrigger>
                            <TabsTrigger value="upload">Z dysku</TabsTrigger>
                        </TabsList>
                        <TabsContent value="url" className="space-y-4 pt-4">
                            <div className="space-y-2">
                                <Label>URL zdjęcia</Label>
                                <Input
                                    value={imageUrl}
                                    onChange={(e) => setImageUrl(e.target.value)}
                                    placeholder="https://example.com/image.jpg"
                                />
                            </div>
                            <Button onClick={addImageFromUrl} disabled={!imageUrl.trim()}>
                                Dodaj zdjęcie
                            </Button>
                        </TabsContent>
                        <TabsContent value="upload" className="space-y-4 pt-4">
                            <div className="space-y-2">
                                <Label>Wybierz plik</Label>
                                <Input
                                    type="file"
                                    accept="image/*"
                                    onChange={(e) => {
                                        const file = e.target.files?.[0]
                                        if (file) {
                                            handleFileUpload(file)
                                            setShowImageDialog(false)
                                        }
                                    }}
                                />
                            </div>
                            <p className="text-sm text-muted-foreground">
                                Maksymalny rozmiar: 5MB. Dozwolone formaty: JPG, PNG, GIF, WebP.
                            </p>
                        </TabsContent>
                    </Tabs>
                </DialogContent>
            </Dialog>

            {/* Dialog do wstawiania HTML */}
            <Dialog open={showHtmlDialog} onOpenChange={setShowHtmlDialog}>
                <DialogContent className="max-w-2xl">
                    <DialogHeader>
                        <DialogTitle>Wstaw kod HTML</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-4">
                        <div className="space-y-2">
                            <Label>Kod HTML</Label>
                            <Textarea
                                value={htmlContent}
                                onChange={(e) => setHtmlContent(e.target.value)}
                                placeholder="<p>Wklej tutaj kod HTML...</p>"
                                className="min-h-[200px] font-mono text-sm"
                            />
                        </div>
                        <p className="text-sm text-muted-foreground">
                            Wklejony HTML zostanie wstawiony w miejscu kursora w edytorze.
                        </p>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setShowHtmlDialog(false)}>
                            Anuluj
                        </Button>
                        <Button onClick={insertHtml} disabled={!htmlContent.trim()}>
                            Wstaw HTML
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    )
}