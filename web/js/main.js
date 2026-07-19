import { createCard, createChip, createEmpty, createTab } from "./components.js"

const state = {
    blogs: [],
    videos: {
        playlists: [],
        marked: [],
        subscriptions: []
    },
    videoTab: "playlists",
    blogTag: null,
    videoTag: null,
}

document.addEventListener("DOMContentLoaded", init)

async function init() {
    await loadState()
    render()
    await playSplash()
}

async function loadState() {
    const { blogs } = await fetch("/meta").then((res) => res.json())
    state.blogs = blogs.map((blog) => ({
        href: blog.href,
        image: blog.image,
        title: blog.title,
        subtitle: blog.description,
    }))
}

function render() {
    renderBlogs()
    renderVideos()
}

function renderBlogs() {
    const blogs = state.blogs.filter((item) => !state.blogTag || item.tags.includes(state.blogTag))

    renderFilters(document.getElementById("blog-filters"), blogs, state.blogTag, (tag) => {
        state.blogTag = tag
        renderBlogs()
    })
    renderGrid(document.getElementById("blog-grid"), blogs, "No blogs found.")
}

function renderVideos() {
    const videos = state.videos[state.videoTab].filter((item) => !state.videoTag || item.tags.includes(state.videoTag))

    renderTabs(document.getElementById("video-tabs"), ["playlists", "marked", "subscriptions"], state.videoTab, (tab) => {
        state.videoTab = tab
        renderVideos()
    })
    renderFilters(document.getElementById("video-filters"), videos, state.videoTag, (tag) => {
        state.videoTag = tag
        renderVideos()
    })
    renderGrid(document.getElementById("video-grid"), videos, "No videos found.")
}

function renderTabs(root, tabs, activeTab, onChange) {
    root.replaceChildren(...tabs.map((tab) => createTab(tab, tab === activeTab, onChange)))
}

function renderFilters(root, items, activeFilter, onChange) {
    const tags = [...new Set(items.flatMap(item => item.tags))].sort()

    if (activeFilter && !tags.includes(activeFilter)) {
        activeFilter = null
        onChange(null)
    }

    root.replaceChildren(...tags.map((tag) => createChip(tag, tag === activeFilter, onChange)))
}

function renderGrid(root, items, emptyMessage) {
    if (!items.length) {
        root.replaceChildren(createEmpty(emptyMessage))
        return
    }

    root.replaceChildren(...items.map(createCard))
}

async function playSplash() {

    // Implement later.

}